-- Loads a manifest of plugin config modules, and installs the plugins those
-- modules add.

---@class loadout.Entry
---@field [1] string module that configures the plugin, such as "plugins/oil"
---@field now? boolean load while the manifest loads, instead of after startup
---@field ft? string|string[] load on FileType for these filetypes
---@field event? string|string[] load on these autocmd events
---@field pattern? string|string[] autocmd pattern for `event`
---@field startup? fun(): boolean also load right after startup when this returns true. It runs on the main loop between frames, so keep it fast.
---@field cond? fun(): boolean load only when this returns true
---@field deps? string[] modules to load first, under this entry's gates and install path
---@field group? string name that toggles this entry together with others
---@field vscode? boolean load when Neovim runs inside VS Code through vscode-neovim
---@field opt_in? boolean stay off until enabled, and install outside nvim-pack-lock.json

---@class loadout.Toggles
---@field disable? string[] entries or groups to keep off
---@field enable? string[] opt-in entries or groups to turn on

---@class loadout.Project: loadout.Toggles
---@field load? (string|loadout.Entry)[] entries this project adds to the manifest
---@field after? fun() runs after every entry that loads at startup has loaded

local M = {}

local local_root = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "loadout", "opt")

local entries = {} ---@type table<string, loadout.Entry>
local groups = {} ---@type table<string, true>
local loaded = {} ---@type table<string, true>
local disabled = {} ---@type table<string, true>
local enabled = {} ---@type table<string, true>
local toggled = {} ---@type { name: string, source: string, disable: boolean? }[]
local queue = {} ---@type fun()[]
local afters = {} ---@type fun()[]?
local current ---@type loadout.Entry?

local function is_skipped(entry)
	local module, group = entry[1], entry.group
	if disabled[module] or (group and disabled[group]) then
		return true
	end
	if entry.opt_in and not (enabled[module] or (group and enabled[group])) then
		return true
	end
	if vim.g.vscode and not entry.vscode then
		return true
	end
	return entry.cond ~= nil and not entry.cond()
end

local function require_as(entry, module)
	local previous = current
	current = entry
	local ok, err = pcall(require, module)
	current = previous
	if not ok then
		vim.notify(("Error loading %s:\n%s"):format(module, err), vim.log.levels.ERROR)
	end
end

local function load_entry(entry)
	if loaded[entry[1]] or is_skipped(entry) then
		return
	end
	loaded[entry[1]] = true
	for _, dep in ipairs(entry.deps or {}) do
		if not loaded[dep] then
			loaded[dep] = true
			require_as(entry, dep)
		end
	end
	require_as(entry, entry[1])
end

local function on_trigger(entry)
	if vim.v.vim_did_enter == 0 then
		-- Startup is still loading argv buffers; the queue keeps load order predictable.
		queue[#queue + 1] = function()
			load_entry(entry)
		end
	else
		load_entry(entry)
	end
end

local function add_entry(entry)
	entries[entry[1]] = entry
	if entry.group then
		groups[entry.group] = true
	end

	if entry.now then
		load_entry(entry)
		return
	end

	local function callback()
		on_trigger(entry)
	end
	if entry.ft then
		vim.api.nvim_create_autocmd("FileType", { pattern = entry.ft, once = true, callback = callback })
	end
	if entry.event then
		vim.api.nvim_create_autocmd(entry.event, { pattern = entry.pattern, once = true, callback = callback })
	end

	if entry.startup then
		queue[#queue + 1] = function()
			if entry.startup() then
				load_entry(entry)
			end
		end
	elseif not (entry.ft or entry.event) then
		queue[#queue + 1] = function()
			load_entry(entry)
		end
	end
end

local function run_afters()
	local callbacks = afters or {}
	afters = nil
	for _, fn in ipairs(callbacks) do
		local ok, err = pcall(fn)
		if not ok then
			vim.notify((".nvim.lua after() error:\n%s"):format(err), vim.log.levels.ERROR)
		end
	end
end

local function drain()
	local load = table.remove(queue, 1)
	if not load then
		run_afters()
		return
	end
	load()
	vim.schedule(drain)
end

local function check_toggles()
	for _, t in ipairs(toggled) do
		if not (entries[t.name] or groups[t.name]) then
			vim.notify(("loadout: %s names no entry or group %q"):format(t.source, t.name), vim.log.levels.WARN)
		elseif t.disable and loaded[t.name] then
			vim.notify(("loadout: %s disables %q, which loaded before it ran"):format(t.source, t.name), vim.log.levels.WARN)
		end
	end
end

local function toggle(opts, source)
	for _, name in ipairs(opts.disable or {}) do
		disabled[name] = true
		toggled[#toggled + 1] = { name = name, source = source, disable = true }
	end
	for _, name in ipairs(opts.enable or {}) do
		enabled[name] = true
		toggled[#toggled + 1] = { name = name, source = source }
	end
end

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		check_toggles()
		vim.schedule(drain)
	end,
})

--- Loads each entry of the manifest: `now` entries at once, the rest after
--- startup or on their triggers.
---@param manifest loadout.Entry[]
function M.load(manifest)
	for _, entry in ipairs(manifest) do
		add_entry(entry)
	end
end

--- Sets this machine's toggles. Call it from lua/local.lua, before the manifest loads.
---@param opts loadout.Toggles
function M.machine(opts)
	toggle(opts, "lua/local.lua")
end

--- Sets this project's toggles. Call it from the project's .nvim.lua. Entries
--- marked `now` have loaded before .nvim.lua runs, so toggles skip them.
---@param opts loadout.Project
function M.project(opts)
	toggle(opts, ".nvim.lua")
	for _, entry in ipairs(opts.load or {}) do
		add_entry(type(entry) == "string" and { entry } or entry)
	end
	if opts.after then
		if afters then
			afters[#afters + 1] = opts.after
		else
			vim.schedule(opts.after)
		end
	end
end

local function git(args)
	local out = vim.system(vim.list_extend({ "git" }, args), { text = true }):wait()
	if out.code ~= 0 then
		error(("git %s failed:\n%s"):format(table.concat(args, " "), out.stderr), 0)
	end
end

local function install_local(spec, load)
	vim.validate("version", spec.version, "string", true)
	local name = spec.name or spec.src:match("([^/\\]+)$"):gsub("%.git$", "")
	local path = vim.fs.joinpath(local_root, name)
	if not vim.uv.fs_stat(path) then
		vim.notify(("Installing %s from %s"):format(name, spec.src))
		git({ "clone", "--filter=blob:none", spec.src, path })
		if spec.version then
			local ok, err = pcall(git, { "-C", path, "checkout", spec.version })
			if not ok then
				vim.fs.rm(path, { recursive = true, force = true })
				error(err, 0)
			end
		end
	end
	vim.cmd({ cmd = "packadd", args = { name }, bang = not load })
end

--- Installs and loads plugins. Takes the same arguments as `vim.pack.add`.
--- Inside an `opt_in` entry, or with `shared = false`, the plugins install
--- outside vim.pack, so they never reach nvim-pack-lock.json or the other
--- machines that share it. Those installs take only a branch, tag, or commit
--- as `version`, and they do not update.
---@param specs (string|vim.pack.Spec)[]
---@param opts? vim.pack.keyset.add|{ shared?: boolean }
function M.add(specs, opts)
	opts = opts or {}
	if opts.shared ~= false and not (current and current.opt_in) then
		local pack_opts = vim.tbl_extend("force", {}, opts)
		pack_opts.shared = nil
		return vim.pack.add(specs, pack_opts)
	end

	local load = vim.F.if_nil(opts.load, vim.v.vim_did_init == 1)
	for _, spec in ipairs(specs) do
		install_local(type(spec) == "string" and { src = spec } or spec, load)
	end
end

--- Returns where plugin `name` is installed, or nil.
---@param name string
---@return string?
function M.get_path(name)
	local path = vim.fs.joinpath(local_root, name)
	if vim.uv.fs_stat(path) then
		return path
	end
	local ok, plugins = pcall(vim.pack.get, { name })
	return ok and plugins[1] and plugins[1].path or nil
end

return M
