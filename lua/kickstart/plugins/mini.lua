return {
	{ -- Collection of various small independent plugins/modules
		'echasnovski/mini.nvim',
		config = function()
			-- Better Around/Inside textobjects
			--
			-- Examples:
			--  - va)  - [V]isually select [A]round [)]paren
			--  - yinq - [Y]ank [I]nside [N]ext [Q]uote
			--  - ci'  - [C]hange [I]nside [']quote
			require('mini.ai').setup { n_lines = 500 }

			-- Add/delete/replace surroundings (brackets, quotes, etc.)
			--
			-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
			-- - sd'   - [S]urround [D]elete [']quotes
			-- - sr)'  - [S]urround [R]eplace [)] [']
			require('mini.surround').setup()

			require('mini.indentscope').setup {
				-- symbol = '│',
				symbol = '┃',
				options = { try_as_border = true },
			}

			-- Simple and easy statusline.
			--  You could remove this setup call if you don't like it,
			--  and try some other statusline plugin
			local statusline = require 'mini.statusline'
			-- set use_icons to true if you have a Nerd Font
			statusline.setup { use_icons = vim.g.have_nerd_font }

			-- You can configure sections in the statusline by overriding their
			-- default behavior. For example, here we set the section for
			-- cursor location to LINE:COLUMN
			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_location = function()
				return '%2l:%-2v'
			end

			-- ... and there is more!
			--  Check out: https://github.com/echasnovski/mini.nvim
		end,
		init = function()
			-- Disable mini indent for certain things
			-- Copied for LazyVim
			vim.api.nvim_create_autocmd('FileType', {
				pattern = {
					'Trouble',
					'alpha',
					'dashboard',
					'fzf',
					'help',
					'lazy',
					'mason',
					'neo-tree',
					'notify',
					'snacks_dashboard',
					'snacks_notif',
					'snacks_terminal',
					'snacks_win',
					'toggleterm',
					'trouble',
				},
				callback = function()
					vim.b.miniindentscope_disable = true
				end,
			})
		end,
	},
}
-- vim: ts=2 sts=2 sw=2 et
