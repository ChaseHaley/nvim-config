if vim.g.vscode then
	return {}
end

return {
	{ -- Add indentation guides even on blank lines
		'lukas-reineke/indent-blankline.nvim',
		dependencies = {
			{ 'nvim-treesitter/nvim-treesitter', branch = 'master' },
			'https://gitlab.com/HiPhish/rainbow-delimiters.nvim',
		},
		-- Enable `lukas-reineke/indent-blankline.nvim`
		-- See `:help ibl`
		main = 'ibl',
		opts = {
			-- scope = {
			-- 	enabled = true,
			-- 	show_start = true,
			-- 	show_end = true,
			-- 	show_exact_scope = true,
			-- },
		},
		config = function()
			local highlight = {
				'RainbowRed',
				'RainbowYellow',
				'RainbowBlue',
				'RainbowOrange',
				'RainbowGreen',
				'RainbowViolet',
				'RainbowCyan',
			}
			local hooks = require 'ibl.hooks'
			-- create the highlight groups in the highlight setup hook, so they are reset
			-- every time the colorscheme changes
			hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
				vim.api.nvim_set_hl(0, 'RainbowRed', { fg = '#E06C75' })
				vim.api.nvim_set_hl(0, 'RainbowYellow', { fg = '#E5C07B' })
				vim.api.nvim_set_hl(0, 'RainbowBlue', { fg = '#61AFEF' })
				vim.api.nvim_set_hl(0, 'RainbowOrange', { fg = '#D19A66' })
				vim.api.nvim_set_hl(0, 'RainbowGreen', { fg = '#98C379' })
				vim.api.nvim_set_hl(0, 'RainbowViolet', { fg = '#C678DD' })
				vim.api.nvim_set_hl(0, 'RainbowCyan', { fg = '#56B6C2' })
			end)

			vim.g.rainbow_delimiters = { highlight = highlight }
			require('ibl').setup { scope = { highlight = highlight } }

			hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
		end,
	},
}
