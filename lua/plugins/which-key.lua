vim.pack.add({ "https://github.com/folke/which-key.nvim" })
require("which-key").setup({
	preset = "helix",
	delay = 0,
	filter = function (mapping)
		return mapping.desc ~= "diffview_ignore"
	end,
	icons = {
		-- set icon mappings to true if you have a Nerd Font
		mappings = vim.g.have_nerd_font,
		-- If you are using a Nerd Font: set icons.keys to an empty table which will use the
		-- default which-key.nvim defined Nerd Font icons, otherwise define a string table
		keys = vim.g.have_nerd_font and {} or {
			Up = "<Up> ",
			Down = "<Down> ",
			Left = "<Left> ",
			Right = "<Right> ",
			C = "<C-…> ",
			M = "<M-…> ",
			D = "<D-…> ",
			S = "<S-…> ",
			CR = "<CR> ",
			Esc = "<Esc> ",
			ScrollWheelDown = "<ScrollWheelDown> ",
			ScrollWheelUp = "<ScrollWheelUp> ",
			NL = "<NL> ",
			BS = "<BS> ",
			Space = "<Space> ",
			Tab = "<Tab> ",
			F1 = "<F1>",
			F2 = "<F2>",
			F3 = "<F3>",
			F4 = "<F4>",
			F5 = "<F5>",
			F6 = "<F6>",
			F7 = "<F7>",
			F8 = "<F8>",
			F9 = "<F9>",
			F10 = "<F10>",
			F11 = "<F11>",
			F12 = "<F12>",
		},
	},

	-- Document existing key chains
	spec = {
		{ "<leader>s", group = "[S]earch" },
		{ "<leader>ss", group = "[S]earch [S]ymbols" },
		{ "<leader>sd", group = "[S]earch [D]iagnostics" },
		{ "<leader>t", group = "[T]oggle" },
		{ "<leader>g", group = "[G]eneral" },
		{ "<leader>gh", group = "Git [h]unk", mode = { "n", "v" } },
		{ "<leader>gn", group = "Neogit" },
		{ "<leader>h", group = "Quickfiles" },
		{ "<leader>grugf", group = "Current [f]ile" },
		{ "<leader>j", group = "[J]oin or split node" },
		{ "<leader>n", group = "[N]o neck pain" },
		{ "<leader>c", group = "[C]laude Code" },
		{ "<leader>z", group = "Custom" },
		{ "<leader>zo", group = "[O]pen file in..." },
		{ "<leader>za", group = "Copy [A]gent mention", mode = { "n", "x" } },
		{ "<leader>x", group = "Trouble" },
		{ "<leader>d", group = "[D]ap" },
	},
})
