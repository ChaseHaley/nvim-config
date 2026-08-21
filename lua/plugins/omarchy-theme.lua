-- Follows the Omarchy system theme (`omarchy theme set ...`).
--
-- Omarchy writes a lazy.nvim spec to ~/.local/state/omarchy/current/theme/neovim.lua:
-- one or more colorscheme plugins, plus a "LazyVim/LazyVim" entry whose opts name
-- the colorscheme to apply. This config uses vim.pack, so the spec is translated
-- rather than consumed by a plugin manager. A poll on the theme marker file picks
-- up theme switches without restarting Neovim.
--
-- Returns false from setup() when Omarchy isn't present (Windows, non-Omarchy
-- Linux), so the caller can fall back to the config's own colorscheme.

local M = {}

local state = vim.fs.joinpath(vim.uv.os_homedir() or "", ".local/state/omarchy/current")
local SPEC = vim.fs.joinpath(state, "theme", "neovim.lua")
-- Rewritten on every theme switch, so it's the cheapest thing to watch.
local MARKER = vim.fs.joinpath(state, "theme.name")

-- Plugins this config already configures itself. Reusing our own module keeps
-- personal tweaks (comment styles, LineNr colors) instead of bare theme defaults.
local OWN_CONFIG = {
	["folke/tokyonight.nvim"] = "plugins.tokyonight",
}

-- Highlight groups to strip backgrounds from, so the terminal shows through.
local TRANSPARENT = {
	"Normal",
	"NormalNC",
	"NormalFloat",
	"FloatBorder",
	"Pmenu",
	"Terminal",
	"EndOfBuffer",
	"FoldColumn",
	"Folded",
	"SignColumn",
	"LineNr",
	"CursorLineNr",
	"WhichKeyFloat",
	"SnacksNormal",
	"SnacksNormalNC",
	"SnacksWinBar",
	"SnacksPicker",
	"SnacksPickerBorder",
	"SnacksPickerPreview",
	"SnacksPickerPreviewBorder",
	"SnacksPickerList",
	"SnacksPickerListBorder",
	"SnacksPickerInput",
	"SnacksPickerInputBorder",
	"SnacksDashboardNormal",
	"OilNormal",
	"TroubleNormal",
	"TroubleNormalNC",
}

local function apply_transparency()
	if vim.g.omarchy_transparency == false then
		return
	end

	for _, name in ipairs(TRANSPARENT) do
		local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
		if ok and next(hl) ~= nil then
			hl.bg = nil
			hl.ctermbg = nil
			pcall(vim.api.nvim_set_hl, 0, name, hl)
		end
	end
end

---@return table? spec, string? err
local function read_spec()
	local chunk, err = loadfile(SPEC)
	if not chunk then
		return nil, err
	end

	local ok, spec = pcall(chunk)
	if not ok or type(spec) ~= "table" then
		return nil, ("%s did not return a spec table"):format(SPEC)
	end

	return spec
end

---@param spec table lazy.nvim spec list
local function parse(spec)
	local plugins, colorscheme, background = {}, nil, nil

	for _, entry in ipairs(spec) do
		local repo = type(entry) == "table" and entry[1]
		if type(repo) == "string" then
			if repo == "LazyVim/LazyVim" then
				local opts = type(entry.opts) == "table" and entry.opts or {}
				colorscheme = opts.colorscheme
				background = opts.background
			else
				plugins[#plugins + 1] = {
					repo = repo,
					name = entry.name,
					version = entry.branch or entry.tag,
					opts = entry.opts,
				}
			end
		end
	end

	return plugins, colorscheme, background
end

-- lazy.nvim derives the module to call setup() on from the plugin's name.
-- Guess the same way so themes that ship opts (aether) get configured.
local function module_candidates(plugin)
	local base = plugin.name or plugin.repo:match("([^/]+)$") or plugin.repo
	local names = {}

	local function add(name)
		if name and name ~= "" and not vim.tbl_contains(names, name) then
			names[#names + 1] = name
		end
	end

	add(base)
	add((base:gsub("%.nvim$", "")))
	add((base:gsub("%-nvim$", "")))
	add((base:gsub("^nvim%-", "")))
	-- "rose-pine/neovim" is required as "rose-pine"
	add(plugin.repo:match("^([^/]+)/"))

	return names
end

-- Force setup() to rerun against fresh state: a theme switch between two variants
-- of the same plugin (Omarchy generates most themes on top of aether) otherwise
-- keeps the colors cached in the plugin's already-loaded modules.
local function unload(plugin)
	local own = OWN_CONFIG[plugin.repo]
	if own then
		package.loaded[own] = nil
	end

	local name = plugin.name or plugin.repo:match("([^/]+)$")
	for _, info in ipairs(vim.pack.get({ name })) do
		local lua = vim.fs.joinpath(info.path, "lua")
		local ok, iter = pcall(vim.fs.dir, lua, { depth = 8 })
		if ok then
			for file, kind in iter do
				if kind == "file" and file:match("%.lua$") then
					local mod = file:gsub("%.lua$", ""):gsub("[/\\]", "."):gsub("%.init$", "")
					package.loaded[mod] = nil
				end
			end
		end
	end
end

local function configure(plugin)
	local own = OWN_CONFIG[plugin.repo]
	if own then
		-- Our own module runs its own vim.pack.add/setup and picks a default
		-- colorscheme; the Omarchy variant is applied over it below.
		pcall(require, own)
		return
	end

	if not plugin.opts then
		return
	end

	for _, name in ipairs(module_candidates(plugin)) do
		local ok, mod = pcall(require, name)
		if ok and type(mod) == "table" and type(mod.setup) == "function" then
			pcall(mod.setup, plugin.opts)
			return
		end
	end
end

---@param reload boolean whether a theme is already applied
---@return boolean ok, string? err
local function apply(reload)
	local spec, err = read_spec()
	if not spec then
		return false, err
	end

	local plugins, colorscheme, background = parse(spec)
	if not colorscheme then
		return false, ("no colorscheme found in %s"):format(SPEC)
	end

	local specs = {}
	for _, plugin in ipairs(plugins) do
		specs[#specs + 1] = {
			src = "https://github.com/" .. plugin.repo,
			name = plugin.name,
			version = plugin.version,
		}
	end

	if #specs > 0 then
		-- confirm = false: a theme switch must not drop a confirmation buffer
		-- on the user just because the new theme's plugin isn't installed yet.
		local ok, add_err = pcall(vim.pack.add, specs, { confirm = false })
		if not ok then
			return false, tostring(add_err)
		end
	end

	if reload then
		vim.cmd("highlight clear")
		if vim.fn.exists("syntax_on") == 1 then
			vim.cmd("syntax reset")
		end
		for _, plugin in ipairs(plugins) do
			unload(plugin)
		end
	end

	for _, plugin in ipairs(plugins) do
		configure(plugin)
	end

	-- LazyVim's `background` opt is 'background'; some themes misuse it for their
	-- own contrast setting, so only pass through the values 'background' accepts.
	if background == "light" or background == "dark" then
		vim.o.background = background
	end

	local ok = pcall(vim.cmd.colorscheme, colorscheme)
	if not ok then
		return false, ("colorscheme %q is not available"):format(colorscheme)
	end

	return true
end

local function watch()
	local poll = vim.uv.new_fs_poll()
	if not poll then
		return
	end

	poll:start(
		MARKER,
		2000,
		vim.schedule_wrap(function()
			local ok, err = apply(true)
			if ok then
				apply_transparency()
				vim.cmd("redraw!")
			elseif err then
				vim.notify(("Omarchy theme reload failed: %s"):format(err), vim.log.levels.WARN)
			end
		end)
	)
end

--- Applies the current Omarchy theme and watches for switches.
--- @return boolean applied false when Omarchy isn't installed or the spec is unusable
function M.setup()
	if vim.uv.fs_stat(SPEC) == nil then
		return false
	end

	local ok, err = apply(false)
	if not ok then
		if err then
			vim.notify(("Omarchy theme not applied: %s"):format(err), vim.log.levels.WARN)
		end
		return false
	end

	apply_transparency()
	-- Plugins that set highlights when they load run after this, and any
	-- :colorscheme reapplies the theme's own groups, so re-strip backgrounds.
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("omarchy-theme-transparency", { clear = true }),
		callback = apply_transparency,
	})

	watch()

	return true
end

return M
