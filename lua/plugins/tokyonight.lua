vim.pack.add({ "https://github.com/folke/tokyonight.nvim" })
require("tokyonight").setup(
	--- @type tokyonight.Config
	{
		styles = {
			comments = { italic = false },
		},
		on_highlights = function(hl, c)
			if vim.fn.has("win32") then
				hl.DiagnosticUnderlineError = { underline = true, sp = c.error }
				hl.DiagnosticUnderlineWarn = { underline = true, sp = c.warning }
			end

			hl.LineNr = { fg = c.comment }
			hl.LineNrAbove = { fg = c.comment }
			hl.LineNrBelow = { fg = c.comment }
		end,
	}
)

vim.cmd.colorscheme("tokyonight")
