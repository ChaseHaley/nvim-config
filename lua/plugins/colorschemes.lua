require("loadout").add({ "https://github.com/folke/tokyonight.nvim" })
require("tokyonight").setup(
	--- @type tokyonight.Config
	{
		transparent = vim.g.transparent_theme,
		styles = {
			comments = { italic = false },
		},
		on_highlights = function(hl, c)
			--[[ if vim.fn.has("win32") == 1 then
				hl.DiagnosticUnderlineError = { underline = true, sp = c.error }
				hl.DiagnosticUnderlineWarn = { underline = true, sp = c.warning }
			end ]]

			hl.LineNr = { fg = c.comment }
			hl.LineNrAbove = { fg = c.comment }
			hl.LineNrBelow = { fg = c.comment }

			local util = require("tokyonight.util")
			hl.DiffAdd = { bg = util.blend_bg(c.green2, 0.45) }
			hl.DiffChange = { bg = util.blend_bg(c.blue, 0.2) }
			hl.DiffText = { bg = util.blend_bg(c.blue0, 0.7) }
		end,
	}
)
--
-- vim.pack.add({ "https://github.com/marko-cerovac/material.nvim" })
-- require("material").setup({})
--
-- vim.pack.add({ "https://github.com/uhs-robert/oasis.nvim" })
-- require("oasis").setup({})
--
-- vim.pack.add({ "https://github.com/datsfilipe/vesper.nvim" })
-- require("vesper").setup({})
--
-- vim.pack.add({ "https://github.com/sontungexpt/witch" })
-- require("witch").setup({})
--
-- vim.pack.add({ "https://github.com/wurli/cobalt.nvim" })
-- require("cobalt").setup({})

require("loadout").add({ "https://github.com/ellisonleao/gruvbox.nvim" })
require("gruvbox").setup()

local function apply_aiodev_theme(theme)
	local tokyonight_style = theme:match("^tokyonight%-(%a+)")
	if tokyonight_style then
		return pcall(vim.cmd.colorscheme, "tokyonight-" .. tokyonight_style)
	end

	local gruvbox_background = theme:match("^gruvbox%-(%a+)")
	if gruvbox_background == "dark" or gruvbox_background == "light" then
		vim.o.background = gruvbox_background
		return pcall(vim.cmd.colorscheme, "gruvbox")
	end

	return false
end

local aio = vim.env.AIODEV_CLI
local applied = false
if aio then
	-- Prints the value in its settings.ini form, quotes included.
	local result = vim.system({ aio, "settings.get", "--name", "theme.name" }, { text = true }):wait(1000)
	local theme = result.code == 0 and result.stdout:match('"(.-)"')
	applied = theme and apply_aiodev_theme(theme) or false

	local pending = ""
	vim.fn.jobstart({ aio, "--json", "events", "settings.changed" }, {
		on_stdout = function(_, lines)
			lines[1] = pending .. lines[1]
			pending = table.remove(lines)
			for _, line in ipairs(lines) do
				local ok, event = pcall(vim.json.decode, line)
				if ok and event.key == "theme.name" then
					apply_aiodev_theme(event.value)
				end
			end
		end,
	})
end

if not applied then
	vim.cmd.colorscheme("tokyonight")
end
