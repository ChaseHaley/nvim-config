vim.pack.add({ gh("sindrets/winshift.nvim") })
require("winshift").setup({})
vim.keymap.set("n", "<M-w>", "<cmd>WinShift<cr>")
