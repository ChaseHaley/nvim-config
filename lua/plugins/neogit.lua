vim.pack.add({ "https://github.com/NeogitOrg/neogit" })
require("neogit").setup(
	---@type NeogitConfig
	{
		graph_style = "unicode",
		disable_insert_on_commit = true,
		commit_editor = {
			kind = "split_below_all",
			show_staged_diff = false,
		},
		popup = {
			kind = "split",
			show_title = true
		}
	}
)

vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Show Neogit UI" })
vim.keymap.set("n", "<leader>gnc", "<cmd>Neogit commit<cr>", { desc = "Neogit commit" })
vim.keymap.set("n", "<leader>gnp", "<cmd>Neogit pull<cr>", { desc = "Neogit pull" })
vim.keymap.set("n", "<leader>gnP", "<cmd>Neogit push<cr>", { desc = "Neogit push" })
vim.keymap.set("n", "<leader>gnr", "<cmd>Neogit rebase<cr>", { desc = "Neogit rebase" })
