return {
	'Wansmer/treesj',
	dependencies = { 'nvim-treesitter/nvim-treesitter' }, -- if you install parsers with `nvim-treesitter`
	event = 'BufEnter',
	config = function()
		require('treesj').setup {
			use_default_keymaps = false,
		}
		vim.keymap.set('n', '<leader>jt', require('treesj').toggle, { desc = 'Toggle node split' })
		vim.keymap.set('n', '<leader>js', require('treesj').split, { desc = 'Split node' })
		vim.keymap.set('n', '<leader>jj', require('treesj').join, { desc = 'Join node' })
	end,
}
