vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" })
require("gitsigns").setup(
	---@type Gitsigns.config
	{
		signs = {
			add = { text = "+" },
			change = { text = "~" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
		},

		-- Make background work less chatty
		watch_gitdir = { interval = 2000, follow_files = false },
		update_debounce = 400, -- delay re-diff after edits/saves

		on_attach = function(bufnr)
			local gitsigns = require("gitsigns")

			-- Navigation
			vim.keymap.set("n", "]c", function()
				if vim.wo.diff then
					vim.cmd.normal({ "]c", bang = true })
				else
					gitsigns.nav_hunk("next")
				end
			end, { desc = "Jump to next git [c]hange" })

			vim.keymap.set("n", "[c", function()
				if vim.wo.diff then
					vim.cmd.normal({ "[c", bang = true })
				else
					gitsigns.nav_hunk("prev")
				end
			end, { desc = "Jump to previous git [c]hange" })

			vim.keymap.set("n", "<leader>gss", function()
				gitsigns.stage_hunk()
			end, { desc = "Stage hunk" })
			vim.keymap.set("n", "<leader>gsr", function()
				gitsigns.reset_hunk()
			end, { desc = "Reset hunk" })
			vim.keymap.set("n", "<leader>gsb", function()
				gitsigns.blame()
			end, { desc = "Blame" })
			vim.keymap.set("n", "<leader>gsl", function()
				gitsigns.blame_line()
			end, { desc = "Blame line" })
		end,
	}
)
