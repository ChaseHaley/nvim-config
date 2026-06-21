vim.pack.add({ "https://github.com/stevearc/oil.nvim" })

require("oil").setup(
	---@type oil.Config
	{
		view_options = {
			show_hidden = true,
		},
		keymaps = {
			["g?"] = { "actions.show_help", mode = "n" },
			["<CR>"] = "actions.select",
			["<M-s>"] = { "actions.select", opts = { vertical = true } },
			["<M-h>"] = { "actions.select", opts = { horizontal = true } },
			["<M-t>"] = { "actions.select", opts = { tab = true } },
			["<M-p>"] = "actions.preview",
			["<C-c>"] = { "actions.close", mode = "n" },
			-- ["<C-l>"] = "actions.refresh",
			["-"] = { "actions.parent", mode = "n" },
			["_"] = { "actions.open_cwd", mode = "n" },
			["`"] = { "actions.cd", mode = "n" },
			["g~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
			["gs"] = { "actions.change_sort", mode = "n" },
			["gx"] = "actions.open_external",
			["g."] = { "actions.toggle_hidden", mode = "n" },
			["g\\"] = { "actions.toggle_trash", mode = "n" },
		},
		use_default_keymaps = false,
	}
)
vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })
