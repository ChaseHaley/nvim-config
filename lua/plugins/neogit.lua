vim.pack.add({ "https://github.com/sindrets/diffview.nvim" })
vim.pack.add({ "https://github.com/NeogitOrg/neogit" })
require("neogit").setup({})

vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Show Neogit UI" })
