vim.pack.add({ "https://github.com/tronikelis/ts-autotag.nvim" })
require("ts-autotag").setup({
	auto_rename = {
		enabled = true,
	},
	filetypes = {
		"typescript",
		"javascript",
		"typescriptreact",
		"javascriptreact",
		"xml",
		"html",
		"templ",
		"php",
		"razor"
	},
})

-- vim.keymap.set("n", "grn", function()
-- 	if not require("ts-autotag").rename() then
-- 		require("live-rename").rename()
-- 	end
-- end)
