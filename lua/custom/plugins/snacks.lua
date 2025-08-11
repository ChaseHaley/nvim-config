return {
	'folke/snacks.nvim',
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		lazygit = { enabled = true },
		git = { enabled = true },
	},
	keys = {
		{
			'<leader>git',
			function()
				Snacks.lazygit()
				-- ---@param opts? snacks.lazygit.Config
				-- Snacks.lazygit.open(opts)
			end,
			desc = 'Lazygit',
		},
	},
}
