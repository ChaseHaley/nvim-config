if vim.g.vscode then
	return {}
end

return {
	'shortcuts/no-neck-pain.nvim',
	version = '*',
	-- config = function()
	-- 	local nnp = require 'no-neck-pain'
	-- 	nnp.enable()
	-- end,
	opts = {
		width = 1440,
	},
}
