return {
	'vuki656/package-info.nvim',
	dependencies = { 'MunifTanjim/nui.nvim' },
	init = function()
		vim.keymap.set('n', '<leader>is', function()
			require('package-info').show { force = true }
		end, { desc = 'Show latest versions' })
	end,
}
