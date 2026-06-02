vim.pack.add({ gh("tpope/vim-repeat") })
vim.pack.add({ cb("andyg/leap.nvim") })

local leap = require("leap")
leap.setup({})

vim.keymap.set({ "n", "x", "o" }, "<leader>f", "<Plug>(leap)")
vim.keymap.set({ "n", "x", "o" }, "<leader>F", "<Plug>(leap-from-window)")

leap.opts.preview_filter = function(ch0, ch1, ch2)
	return not (ch1:match("%s") or ch0:match("%a") and ch1:match("%a") and ch2:match("%a"))
end

leap.opts.equivalence_classes = { " \t\r\n", "([{", ")]}", "'\"`" }
