require("which-key")
-- vim.pack.add({ { src = "C:/Users/chale/plugins/quickfiles.nvim" } })
-- vim.o.runtimepath:append("C:/Users/chale/plugins/quickfiles.nvim")
vim.pack.add({ "https://github.com/ChaseHaley/quickfiles.nvim" })
require("quickfiles").setup(
	{
		which_key = {
			enabled = true,
			jump_leader = ";"
		}
	}
)

vim.keymap.set("n", "<leader>ht", function()
	require("quickfiles"):mark()
end, { desc = "Quickfile tag" })
-- vim.keymap.set("n", "<leader>;", function()
-- 	require("quickfiles"):jump()
-- end, { desc = "Quickfile jump" })

vim.keymap.set("n", "<leader>hr", function()
	require("quickfiles"):remove()
end, { desc = "Quickfile remove" })
vim.keymap.set("n", "<leader>hc", function()
	require("quickfiles"):clear()
end, { desc = "Quickfile clear" })
vim.keymap.set("n", "<leader>hk", function()
	require("quickfiles"):clear_key()
end, { desc = "Quickfile clear key" })
vim.keymap.set("n", "<leader>hp", function()
	vim.print(require("quickfiles"):list())
end, { desc = "Quickfile print" })
vim.keymap.set("n", "<leader>hf", function()
	vim.print(require("quickfiles"):pick())
end, { desc = "Quickfile pick" })
