-- Defers a plugin config file until startup has finished, so the first frame
-- isn't blocked by plugin setup. Files run in their queued order, one per
-- event-loop tick, and each file's config runs exactly as written.
--
-- An optional autocmd trigger loads the file only once the autocmd fires, so
-- plugins that are only useful in certain sessions can skip loading entirely.
-- A module may be registered with multiple triggers by calling later() again;
-- whichever fires first loads it (require makes repeat loads a no-op).

local queue = {}

local function load(module)
	local ok, err = pcall(require, module)
	if not ok then
		vim.notify(("Error loading %s:\n%s"):format(module, err), vim.log.levels.ERROR)
	end
end

local function drain()
	local module = table.remove(queue, 1)
	if not module then
		return
	end
	load(module)
	vim.schedule(drain)
end

if vim.v.vim_did_enter == 1 then
	vim.schedule(drain)
else
	vim.api.nvim_create_autocmd("VimEnter", {
		once = true,
		callback = function()
			vim.schedule(drain)
		end,
	})
end

---@param module string
---@param trigger? { event: vim.api.keyset.events|vim.api.keyset.events[], opts?: vim.api.keyset.create_autocmd }
--- Autocmd that loads the module. Without one, the module loads right after
--- startup. `once` defaults to true; `callback`/`command` are replaced by the
--- module load, everything else passes through.
return function(module, trigger)
	if not trigger then
		queue[#queue + 1] = module
		return
	end

	local opts = vim.tbl_extend("force", { once = true }, trigger.opts or {})
	opts.command = nil
	opts.callback = function()
		if vim.v.vim_did_enter == 0 then
			-- Startup is still loading argv buffers; let the post-startup
			-- queue handle it so load order stays predictable.
			queue[#queue + 1] = module
		else
			load(module)
		end
	end

	vim.api.nvim_create_autocmd(trigger.event, opts)
end
