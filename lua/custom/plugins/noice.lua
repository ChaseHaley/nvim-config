if vim.g.vscode then
	return {}
end

return {
	'folke/noice.nvim',
	event = 'VeryLazy',
	--- @module 'noice'
	--- @type NoiceConfig
	opts = {
		-- add any options here
		lsp = {
			progress = { enabled = false },
			hover = { enabled = false },
			signature = { enabled = false, auto_open = { enabled = false } },
		},
	},
	dependencies = {
		-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
		'MunifTanjim/nui.nvim',
		-- OPTIONAL:
		--   `nvim-notify` is only needed, if you want to use the notification view.
		--   If not available, we use `mini` as the fallback
		'rcarriga/nvim-notify',
	},
}
