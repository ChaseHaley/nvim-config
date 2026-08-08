vim.pack.add({ "https://gitlab.com/HiPhish/rainbow-delimiters.nvim" })
require("rainbow-delimiters.setup").setup({})

vim.pack.add({ "https://github.com/lukas-reineke/indent-blankline.nvim" })
local highlight = {
	"RainbowRed",
	"RainbowYellow",
	"RainbowBlue",
	"RainbowOrange",
	"RainbowGreen",
	"RainbowViolet",
	"RainbowCyan",
}
local hooks = require("ibl.hooks")
-- create the highlight groups in the highlight setup hook, so they are reset
-- every time the colorscheme changes
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
	vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
	vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
	vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
	vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
	vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
	vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
	vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
end)

vim.g.rainbow_delimiters = { highlight = highlight }

local spaces_ignored = false

local function setup()
	---@type ibl.config
	local opts = {
		scope = { highlight = highlight, char = "▎" },
		-- Indicate when spaces are being used instead of tabs, but keep scope highlights visible regardless of indent
		indent = {
			highlight = "RainbowRed",
			char = "▎", -- space indentation -> visible red bar (warning)
			tab_char = " ", -- tab indentation -> invisible
		},
		exclude = {
			filetypes = {
				"fyler-finder"
			}
		}
	}

	require("ibl").setup(opts)
end

setup()

hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)

vim.api.nvim_create_user_command("IgnoreSpaces", function ()
	---@type ibl.config
	local opts = {
		scope = { highlight = highlight, char = "▎" },
		indent = {
			highlight = highlight,
			tab_char = " ",
			char = " "
		},
		exclude = {
			filetypes = {
				"fyler-finder"
			}
		},
	}

	require("ibl").setup(opts)
	spaces_ignored = true
end, {})

vim.api.nvim_create_user_command("ShowSpaces", function ()
	setup()
	spaces_ignored = false
end, {})

vim.keymap.set("n", "<leader>ts", function()
	if not spaces_ignored then
		vim.cmd.IgnoreSpaces()
	else
		vim.cmd.ShowSpaces()
	end
end, { desc = "Ignore spaces" })
