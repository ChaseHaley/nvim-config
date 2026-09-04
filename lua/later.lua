-- Defers a plugin config file until startup has finished, so the first frame
-- isn't blocked by plugin setup. Files run in their queued order, one per
-- event-loop tick, and each file's config runs exactly as written.
--
-- An optional autocmd trigger loads the file only once the autocmd fires, so
-- plugins that are only useful in certain sessions can skip loading entirely.
-- A condition trigger keeps the file in the queue and loads it only when the
-- predicate returns true. A module may be registered with multiple triggers by
-- calling later() again; whichever fires first loads it (require makes repeat
-- loads a no-op).

local smartload = require("smartload")

local queue = {}

local function load(module)
	if smartload.off[module] then
		return
	end
	local ok, err = pcall(require, module)
	if not ok then
		vim.notify(("Error loading %s:\n%s"):format(module, err), vim.log.levels.ERROR)
	end
end

local function drain()
	local entry = table.remove(queue, 1)
	if not entry then
		return
	end
	if not entry.cond or entry.cond() then
		load(entry.module)
	end
	vim.schedule(drain)
end

smartload.on_vim_enter(drain)

---@param module string
---@param trigger? { event?: vim.api.keyset.events|vim.api.keyset.events[], opts?: vim.api.keyset.create_autocmd, cond?: fun(): boolean }
---@param now? boolean
--- What loads the module. Without a trigger, the module loads right after
--- startup. With `event`, an autocmd loads it; `once` defaults to true,
--- `callback`/`command` are replaced by the module load, everything else passes
--- through. With `cond`, the module loads right after startup only when the
--- predicate returns true. The predicate runs on the main loop between frames,
--- so keep it fast.
return function(module, trigger, now)
	if not trigger then
		queue[#queue + 1] = { module = module }
		return
	end

	if trigger.cond then
		queue[#queue + 1] = { module = module, cond = trigger.cond }
		return
	end

	if now == true then
		load(module)
	end

	local opts = vim.tbl_extend("force", { once = true }, trigger.opts or {})
	opts.command = nil
	opts.callback = function()
		if vim.v.vim_did_enter == 0 then
			-- Startup is still loading argv buffers; let the post-startup
			-- queue handle it so load order stays predictable.
			queue[#queue + 1] = { module = module }
		else
			load(module)
		end
	end

	vim.api.nvim_create_autocmd(trigger.event, opts)
end
