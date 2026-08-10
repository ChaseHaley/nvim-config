local M = {}

M.on_save = function()
	if not package.loaded["no-neck-pain"] then
		return nil
	end
	local state = require("no-neck-pain.state")
	local enabled = {}
	if state.enabled then
		for i, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
			if state.tabs[tabpage] ~= nil then
				enabled[tostring(i)] = true
			end
		end
	end
	return enabled
end

M.on_post_load = function(data)
	if not package.loaded["no-neck-pain"] then
		return
	end
	local main = require("no-neck-pain.main")
	local state = require("no-neck-pain.state")
	local win = vim.api.nvim_get_current_win()

	for i, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
		if data[tostring(i)] then
			vim.api.nvim_set_current_tabpage(tabpage)
			-- The load closed every window, so a tab still held in the plugin
			-- state points at side windows that are gone. main.enable() reads
			-- active_tab to decide whether a tab is already set up, and the
			-- TabEnter autocmd that normally keeps it current cannot run
			-- because resession loads with 'eventignore' set to all.
			state.tabs[tabpage] = nil
			state:set_active_tab(tabpage)
			pcall(main.enable, "resession")
		end
	end

	pcall(vim.api.nvim_set_current_win, win)
end

return M
