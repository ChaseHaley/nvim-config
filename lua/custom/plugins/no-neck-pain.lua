if vim.g.vscode then
	return {}
end

return {
	'shortcuts/no-neck-pain.nvim',
	version = '*',
	config = function()
		require('no-neck-pain').setup {
			width = 200,
			buffers = {
				right = {
					enabled = false,
				},
			},
			autocmds = {
				enableOnVimEnter = true,
			},
			mappings = {
				enabled = true,
			},
		}
	end,
}
