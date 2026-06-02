vim.pack.add({ gh("stevearc/oil.nvim") })

require("oil").setup({})
vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })
