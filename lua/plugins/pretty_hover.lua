vim.pack.add({ "https://github.com/Fildo7525/pretty_hover" })
require("pretty_hover").setup({})

vim.keymap.set("n", "K", function ()
	require("pretty_hover").hover()
end)
