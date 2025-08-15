if vim.g.vscode then
	return {}
end

return {
	{
		'stevearc/conform.nvim',
		event = { 'BufWritePre' },
		cmd = { 'ConformInfo' },
		keys = {
			{
				'<leader>f',
				function()
					require('conform').format { async = true, lsp_format = 'fallback' }
				end,
				mode = '',
				desc = '[F]ormat buffer',
			},
		},
		opts = {
			notify_on_error = false,
			formatters_by_ft = {
				lua = { 'stylua' },
				javascript = { 'eslint_d' },
				typescript = { 'eslint_d' },
				css = { 'prettierd' },
				scss = { 'prettierd' },
			},

			formatters = {
				prettierd = {
					args = { '--stdin-from-filename', '$FILENAME' },
					inherit = true,
					append_args = { '--use-tabs', '--tab-width', '4' },
					--      command = 'prettierd',
					-- args = { vim.api.nvim_buf_get_name(0), '--use-tabs', '--tab-width', '4' },
					--      stdin = true
				},
			},
		},
	},
}
-- vim: ts=2 sts=2 sw=2 et
