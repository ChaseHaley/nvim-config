return {
	'sindrets/winshift.nvim',
	init = function ()
		vim.keymap.set('n', '<M-w>', '<Cmd>WinShift<CR>');
	end
}
