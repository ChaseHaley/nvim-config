vim.pack.add({ "https://github.com/folke/flash.nvim" })
local flash = require("flash")
vim.keymap.set({ "n", "x", "o" }, "<leader>f", function() flash.jump() end, { desc = "Flash" })
vim.keymap.set({ "n", "x", "o" }, "<leader>F", function() flash.treesitter() end, { desc = "Flash Treesitter" })
