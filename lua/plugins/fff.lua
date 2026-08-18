vim.pack.add({ "https://github.com/dmtrKovalenko/fff" })

---@type FffConfig
opts = {
	layout = {
		border = "rounded",
	}
}

require("fff").setup(opts)

vim.keymap.set("n", "<leader>sf", function()
	require("fff").find_files()
end, { desc = "[S]earch [F]iles" })

vim.keymap.set("n", "<leader>sg", function()
	require("fff").live_grep()
end, { desc = "[S]earch by [G]rep" })
