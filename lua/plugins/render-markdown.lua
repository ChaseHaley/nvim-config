-- requires nvim-treesitter/nvim-treesitter and (nvim-tree/nvim-web-devicons or echasnovski/mini.icons)
vim.pack.add({ "https://github.com/MeanderingProgrammer/render-markdown.nvim" })

--- @module 'render-markdown'
--- @type render.md.Userconfig
local opts = {
	completions = {
		blink = {
			enabled = true,
		},
	},
}

require("render-markdown").setup(opts)
