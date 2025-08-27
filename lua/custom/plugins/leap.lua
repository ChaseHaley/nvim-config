return {
	'ggandor/leap.nvim',
	dependences = { 'tpope/vim-repeat' },
	lazy = false,
	config = function()
		require('leap').setup {}

		vim.keymap.set({'n', 'x', 'o'}, '<leader>f', '<Plug>(leap)')
		vim.keymap.set({'n', 'x', 'o'}, '<leader>F', '<Plug>(leap-from-window)')

		require('leap').opts.preview_filter = function(ch0, ch1, ch2)
			return not (ch1:match '%s' or ch0:match '%a' and ch1:match '%a' and ch2:match '%a')
		end
		require('leap').opts.equivalence_classes = { ' \t\r\n', '([{', ')]}', '\'"`' }
		require('leap.user').set_repeat_keys('<enter>', '<backspace>')
	end,
}
