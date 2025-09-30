return {
	'sindrets/diffview.nvim',
	init = function ()
		vim.keymap.set('n', '<leader>gdf', '<cmd>DiffviewFileHistory --follow %<CR>')
		vim.keymap.set('n', '<leader>gda', '<cmd>DiffviewOpen<CR>')
	end
}
