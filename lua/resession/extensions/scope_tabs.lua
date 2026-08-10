-- Replaces the extension that ships with scope.nvim. That one stores the cache
-- as a plain array but scope reads it back by tabpage handle, and a session load
-- makes tabpages with new handles, so every tab ends up with the wrong buffers.
local M = {}

M.on_save = function()
	if not package.loaded["scope"] then
		return nil
	end
	local core = require("scope.core")
	local utils = require("scope.utils")
	core.revalidate()
	local scoped = {}
	for i, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
		scoped[tostring(i)] = utils.get_buffer_names(core.cache[tabpage] or {})
	end
	return scoped
end

M.on_post_load = function(data)
	local core = require("scope.core")
	local cache = {}
	for i, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
		local bufs = {}
		for _, name in ipairs(data[tostring(i)] or {}) do
			if name ~= "" then
				table.insert(bufs, vim.fn.bufadd(name))
			end
		end
		cache[tabpage] = bufs
	end
	core.cache = cache
	core.last_tab = vim.api.nvim_get_current_tabpage()
	core.on_tab_enter()
end

return M
