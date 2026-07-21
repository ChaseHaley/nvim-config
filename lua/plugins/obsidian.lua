vim.pack.add({
	{
		src = "https://github.com/obsidian-nvim/obsidian.nvim",
		version = vim.version.range("*"),
	},
})

require("obsidian").setup(
	---@module 'obsidian'
	---@type obsidian.config
	{
		picker = { name = "snacks.picker" },
		legacy_commands = false,
		open = {
			func = function(uri)
				uri = uri:gsub("%%5[Cc]", "/")
				vim.system({ "pwsh", "-NoProfile", "-NonInteractive", "-Command", ("Start-Process '%s'"):format(uri) })
			end,
		},
		workspaces = {
			{ name = "Main", path = "C:\\Users\\chaley\\Obsidian\\Main" },
		},
	}
)

vim.api.nvim_create_autocmd("User", {
	pattern = "ObsidianNoteEnter",
	callback = function (ev)
		vim.keymap.set("n", "<leader>oa", "<cmd>Obsidian open<cr>", {
			buffer = true,
			desc = "Open in Obsidian"
		})
	end,
})

vim.keymap.set('n', '<leader>oo', '<cmd>Obsidian quick_switch<cr>', { desc = "[O]bsidian" })
vim.keymap.set('n', '<leader>ot', '<cmd>Obsidian tags<cr>', { desc = "[O]bsidian [T]ags" })
vim.keymap.set('n', '<leader>og', '<cmd>Obsidian search<cr>', { desc = "[O]bsidian [G]rep" })
vim.keymap.set('n', '<leader>ohh', '<cmd>Obsidian help<cr>', { desc = "[O]bsidian [H]elp" })
vim.keymap.set('n', '<leader>ohg', '<cmd>Obsidian helpgrep<cr>', { desc = "[O]bsidian [H]elp [G]rep" })
