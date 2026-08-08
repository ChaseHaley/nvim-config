vim.pack.add({ "https://github.com/NeogitOrg/neogit" })
require("neogit").setup({ integrations = { diffview = true } })

vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Show Neogit UI" })
