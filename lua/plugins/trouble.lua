vim.pack.add({ "https://github.com/folke/trouble.nvim" })
local trouble = require("trouble")
trouble.setup(
	---@type trouble.Config
	{
		modes = {
			diagnostics_warn_error = {
				mode = "diagnostics",
				filter = function(items)
					return vim.tbl_filter(function(item)
						return item.severity <= vim.diagnostic.severity.WARN
					end, items)
				end,
			},
		},
	}
)

vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics_warn_error toggle<cr>", { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>xa", "<cmd>Trouble diagnostics toggle<cr>", { desc = "[A]ll Diagnostics" })
vim.keymap.set("n", "<leader>xf", "<cmd>Trouble diagnostics focus<cr>", { desc = "[F]ocus diagnostics" })
vim.keymap.set("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer diagnostics" })
vim.keymap.set("n", "]x", function ()
	trouble.next({ jump = true })
end, { desc = "Go to next Trouble item" })
vim.keymap.set("n", "[x", function ()
	trouble.prev({ jump = true })
end, { desc = "Go to next Trouble item" })
-- vim.keymap.set("n", "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols" })
-- vim.keymap.set("n", "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", { desc = "LSP Definitions / references / ... (Trouble)" })
-- vim.keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
vim.keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })
