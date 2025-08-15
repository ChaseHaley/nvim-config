if vim.g.vscode then
	return {}
end

return {
	'MagicDuck/grug-far.nvim',
	config = function()
		local grug = require 'grug-far'
		--- @param char string
		--- @param func function
		--- @return nil
		local function map(char, func, desc)
			vim.keymap.set({ 'n', 'x' }, '<leader>grug' .. char, func, { desc = desc })
		end

		map(' ', function()
			grug.open()
		end, 'Find and replace across all files')

		map('w', function()
			grug.open { prefills = { search = vim.fn.expand '<cword>' } }
		end, 'Find and replace current word across all files')

		map('s', function()
			grug.open { visualSelectionUsage = 'operate-within-range' }
		end, 'Find and replace in selection')

		map('f ', function()
			grug.open { prefills = { paths = vim.fn.expand '%' } }
		end, 'Find and replace in current file')

		map('fw', function()
			grug.open { prefills = { search = vim.fn.expand '<cword>', paths = vim.fn.expand '%' } }
		end, 'Find and replace current word across all files')

		map('fs', function()
			grug.with_visual_selection { prefills = { paths = vim.fn.expand '%' } }
		end, 'Find and replace selection in current file')
	end,
}
