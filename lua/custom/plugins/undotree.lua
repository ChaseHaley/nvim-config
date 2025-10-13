return {
	'mbbill/undotree',
	init = function ()
		vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = '[U]ndo Tree' })
		vim.g.undotree_WindowLayout = 2
	end
}
