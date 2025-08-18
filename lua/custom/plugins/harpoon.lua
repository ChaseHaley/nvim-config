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
			local finder = function()
				local paths = {}
				for _, item in ipairs(harpoon_files.items) do
					table.insert(paths, item.value)
				end

				return require('telescope.finders').new_table {
					results = paths,
				}
			end

			require('telescope.pickers')
				.new({}, {
					prompt_title = 'Harpoon',
					finder = finder(),
					previewer = false,
					sorter = require('telescope.config').values.generic_sorter {},
					layout_config = {
						height = 0.4,
						width = 0.5,
						prompt_position = 'top',
						preview_cutoff = 120,
					},
					attach_mappings = function(prompt_bufnr, map)
						map('i', '<C-d>', function()
							local state = require 'telescope.actions.state'
							local selected_entry = state.get_selected_entry()
							local current_picker = state.get_current_picker(prompt_bufnr)

							table.remove(harpoon_files.items, selected_entry.index)
							current_picker:refresh(finder())
							vim.defer_fn(function()
								current_picker:move_selection(0 - selected_entry.index + 2)
							end, 10)
						end)

						local function swap_entries(delta)
							local state = require 'telescope.actions.state'
							local sel = state.get_selected_entry()
							if not sel or sel.index == nil then
								return
							end
							local idx = sel.index
							local target = idx + delta
							if target < 1 then
								target = #harpoon_files.items
							elseif target > #harpoon_files.items then
								target = 1
							end

							-- swap in the items list
							harpoon_files.items[idx], harpoon_files.items[target] = harpoon_files.items[target], harpoon_files.items[idx]

							-- refresh finder
							local picker = state.get_current_picker(prompt_bufnr)
							picker:refresh(finder(), { reset_prompt = false })
							vim.defer_fn(function()
								picker:move_selection(0 - target + 1)
							end, 10)
						end

						map('i', '<M-k>', function()
							swap_entries(1)
						end)
						map('i', '<M-j>', function()
							swap_entries(-1)
						end)

						return true
					end,
				})
				:find()

			-- require('telescope.pickers')
			-- 	.new({}, {
			-- 		prompt_title = 'Harpoon',
			-- 		finder = finder(),
			-- 		previewer = conf.file_previewer {},
			-- 		sorter = conf.generic_sorter {},
			-- 		attach_mappings = function(prompt, bufnr, map)
			-- 			map('i', '<C-d>', function()
			-- 				local state = require 'telescope.actions.state'
			-- 				local selected_entry = state.get_selected_etrny()
			-- 				local current_picker = state.get_current_picker(prompt_bufnr)
			--
			-- 				table.remove(harpoon_files.items, selected_entry.index)
			-- 				current_picker:refresh(finder())
			-- 			end)
			-- 			return true
			-- 		end,
			-- 	})
			-- 	:find()
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
