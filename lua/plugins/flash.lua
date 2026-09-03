vim.pack.add({ "https://github.com/folke/flash.nvim" })
local flash = require("flash")
flash.setup({
	modes = {
		search = {
			enabled = false,
		},
		char = {
			highlight = {
				backdrop = false,
			},
		},
	},
	highlight = {
		backdrop = false,
	},
})
vim.keymap.set({ "n", "x", "o" }, "<leader>f", function()
	flash.jump()
end, { desc = "Flash" })
vim.keymap.set({ "n", "x", "o" }, "<leader>F", function()
	flash.treesitter()
end, { desc = "Flash Treesitter" })
