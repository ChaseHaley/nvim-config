vim.pack.add({ "https://github.com/cbochs/grapple.nvim" })
require("grapple").setup({
	scope = "git",
	icons = true,
	status = true,
})

vim.keymap.set("n", "<leader>ht", "<cmd>Grapple toggle<cr>", { desc = "Tag a file" })
vim.keymap.set("n", "<leader>hh", "<cmd>Grapple toggle_tags<cr>", { desc = "Toggle tags menu" })
vim.keymap.set("n", "<leader>hn", "<cmd>Grapple cycle_tags next<cr>", { desc = "Cycle next tag" })
vim.keymap.set("n", "<leader>hp", "<cmd>Grapple cycle_tags prev<cr>", { desc = "Cycle previous tag" })

vim.keymap.set("n", "<leader>ha", "<cmd>Grapple select index=1<cr>", { desc = "Select first tag" })
vim.keymap.set("n", "<leader>hs", "<cmd>Grapple select index=2<cr>", { desc = "Select first tag" })
vim.keymap.set("n", "<leader>hd", "<cmd>Grapple select index=3<cr>", { desc = "Select first tag" })
vim.keymap.set("n", "<leader>hf", "<cmd>Grapple select index=4<cr>", { desc = "Select first tag" })

vim.keymap.set("n", "<leader>h;a", "<cmd>Grapple select index=5<cr>", { desc = "Select first tag" })
vim.keymap.set("n", "<leader>h;s", "<cmd>Grapple select index=6<cr>", { desc = "Select first tag" })
vim.keymap.set("n", "<leader>h;d", "<cmd>Grapple select index=7<cr>", { desc = "Select first tag" })
vim.keymap.set("n", "<leader>h;f", "<cmd>Grapple select index=8<cr>", { desc = "Select first tag" })
