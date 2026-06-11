vim.pack.add({ gh("sindrets/diffview.nvim") })
vim.pack.add({ gh("NeogitOrg/neogit") })
require("neogit").setup({})

vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Show Neogit UI" })
