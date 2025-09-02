return {
	'sindrets/diffview.nvim',
	init = function ()
		vim.keymap.set('n', '<leader>df', '<cmd>DiffviewFileHistory %<CR>')
	end
}
