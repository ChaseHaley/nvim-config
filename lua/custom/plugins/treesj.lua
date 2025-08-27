return {
	'Wansmer/treesj',
	dependencies = { 'nvim-treesitter/nvim-treesitter' }, -- if you install parsers with `nvim-treesitter`
	event = 'BufEnter',
	config = function()
		local csharp = require('treesj_langs_csharp')
		require('treesj').setup {
			use_default_keymaps = false,
			max_join_length = 200,
			langs = {
				c_sharp = csharp
			}
		}
		vim.keymap.set('n', '<leader>jt', require('treesj').toggle, { desc = 'Toggle node split' })
		vim.keymap.set('n', '<leader>js', require('treesj').split, { desc = 'Split node' })
		vim.keymap.set('n', '<leader>jj', require('treesj').join, { desc = 'Join node' })
	end,
}
