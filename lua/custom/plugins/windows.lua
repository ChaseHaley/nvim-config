return {
	'anuvyklack/windows.nvim',
	dependencies = {
		'anuvyklack/middleclass',
		'anuvyklack/animation.nvim',
	},
	config = function()
		-- vim.o.winwidth = 5
		-- vim.o.winminwidth = 5
		vim.o.equalalways = false
		require('windows').setup {
			autowidth = {
				enable = false,
			},
		}

		vim.keymap.set('n', '<C-w>z', '<Cmd>WindowsMaximize<CR>')
		vim.keymap.set('n', '<C-w>_', '<Cmd>WindowsMaximizeVertically<CR>')
		vim.keymap.set('n', '<C-w>|', '<Cmd>WindowsMaximizeHorizontally<CR>')
		vim.keymap.set('n', '<C-w>=', '<Cmd>WindowsEqualize<CR>')
	end,
}
