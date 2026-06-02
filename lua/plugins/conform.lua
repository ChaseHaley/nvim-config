vim.pack.add({ gh("stevearc/conform.nvim") })
require("conform").setup({
	notify_on_error = false,
	formatters_by_ft = {
		lua = { "stylua" },
		javascript = { "eslint_d" },
		typescript = { "eslint_d" },
		css = { "prettierd" },
		scss = { "prettierd" },
		cpp = { "clang-format" },
	},
	formatters = {
		prettierd = {
			args = { "--stdin-from-filename", "$FILENAME" },
			inherit = true,
			append_args = { "--use-tabs", "--tab-width", "4" },
		},
	},
})

vim.keymap.set("n", "<S-M-f>", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "[F]ormat buffer" })
