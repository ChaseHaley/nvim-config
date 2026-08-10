local M = {}

M.on_save = function()
	if not package.loaded["tabby"] then
		return nil
	end
	local tab_name = require("tabby.feature.tab_name")
	local names = {}
	for i, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
		local name = tab_name.get_raw(tabpage)
		if name ~= "" then
			names[tostring(i)] = name
		end
	end
	return names
end

M.on_post_load = function(data)
	local tab_name = require("tabby.feature.tab_name")
	for i, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
		local name = data[tostring(i)]
		if name then
			tab_name.set(tabpage, name)
		end
	end
end

return M
