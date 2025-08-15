return {
	'ThePrimeagen/harpoon',
	branch = 'harpoon2',
	dependencies = {
		'nvim-lua/plenary.nvim',
		'nvim-telescope/telescope.nvim',
	},
	config = function()
		local harpoon = require 'harpoon'
		harpoon:setup()

		-- Enable telescope support
		local conf = require('telescope.config').values
		local function toggle_telescope(harpoon_files)
			local file_paths = {}
			for _, item in ipairs(harpoon_files.items) do
				table.insert(file_paths, item.value)
			end

			require('telescope.pickers')
				.new({}, {
					prompt_title = 'Harpoon',
					finder = require('telescope.finders').new_table {
						results = file_paths,
					},
					previewer = conf.file_previewer {},
					sorter = conf.generic_sorter {},
				})
				:find()
		end

		vim.keymap.set('n', '<leader>ho', function()
			harpoon:list():prepend()
		end, { desc = 'Prepend current buffer' })

		vim.keymap.set('n', '<leader>hp', function()
			harpoon:list():add()
		end, { desc = 'Append current buffer' })

		vim.keymap.set('n', '<leader>hh', function()
			toggle_telescope(harpoon:list())
		end, { desc = 'View all files' })

		vim.keymap.set('n', '<leader>ha', function()
			harpoon:list():select(1)
		end, { desc = 'Go to file 1' })

		vim.keymap.set('n', '<leader>hs', function()
			harpoon:list():select(2)
		end, { desc = 'Go to file 2' })

		vim.keymap.set('n', '<leader>hd', function()
			harpoon:list():select(3)
		end, { desc = 'Go to file 3' })

		vim.keymap.set('n', '<leader>hf', function()
			harpoon:list():select(4)
		end, { desc = 'Go to file 4' })

		vim.keymap.set('n', '<leader>hq', function()
			harpoon:list():prev()
		end, { desc = 'Go to previous file' })

		vim.keymap.set('n', '<leader>hw', function()
			harpoon:list():next()
		end, { desc = 'Go to next file' })

		vim.keymap.set('n', '<leader>hc', function()
			harpoon:list():clear()
		end, { desc = 'Clear list' })

		vim.keymap.set('n', '<leader>hr', function()
			harpoon:list():remove()
		end, { desc = 'Remove current buffer' })
	end,
}
