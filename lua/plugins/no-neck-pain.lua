vim.pack.add({ gh("shortcuts/no-neck-pain.nvim") })
require("no-neck-pain").setup({
	width = 188,
	buffers = {
		-- right == {
		-- 	enabled = false,
		-- },
	},
	autocmds = {
		enableOnVimEnter = true,
	},
	mappings = {
		enabled = true,
	},
})
