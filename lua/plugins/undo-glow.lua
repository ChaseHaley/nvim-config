vim.pack.add({ "https://github.com/y3owk1n/undo-glow.nvim" })

--- @type UndoGlow.Config
local opts = {
	animation = {
		enabled = true,
		duration = 300,
		animation_type = "zoom",
		window_scoped = true,
	},
	highlights = {
		undo = {
			hl_color = { bg = "#693232" }, -- Dark muted red
		},
		redo = {
			hl_color = { bg = "#2F4640" }, -- Dark muted green
		},
		yank = {
			hl_color = { bg = "#7A683A" }, -- Dark muted yellow
		},
		paste = {
			hl_color = { bg = "#325B5B" }, -- Dark muted cyan
		},
		search = {
			hl_color = { bg = "#5C475C" }, -- Dark muted purple
		},
		comment = {
			hl_color = { bg = "#7A5A3D" }, -- Dark muted orange
		},
		cursor = {
			hl_color = { bg = "#793D54" }, -- Dark muted pink
		},
	},
	priority = 2048 * 3,
}

require("undo-glow").setup(opts)

vim.keymap.set("n", "u", function()
	require("undo-glow").undo()
end, { desc = "Undo with highlight", noremap = true })

vim.keymap.set("n", "<C-R>", function()
	require("undo-glow").redo()
end, { desc = "Redo with highlight", noremap = true })

vim.keymap.set("n", "p", function()
	require("undo-glow").paste_below()
end, { desc = "Paste below with highlight", noremap = true })

vim.keymap.set("n", "P", function()
	require("undo-glow").paste_above()
end, { desc = "Paste above with highlight", noremap = true })

vim.keymap.set("n", "n", function()
	require("undo-glow").search_next({
		animation = {
			animation_type = "strobe",
		},
	})
end, { desc = "Search next with highlight", noremap = true })

vim.keymap.set("n", "N", function()
	require("undo-glow").search_prev({
		animation = {
			animation_type = "strobe",
		},
	})
end, { desc = "Search prev with highlight", noremap = true })

vim.keymap.set("n", "*", function()
	require("undo-glow").search_star({
		animation = {
			animation_type = "strobe",
		},
	})
end, { desc = "Search star with highlight", noremap = true })

vim.keymap.set("n", "#", function()
	require("undo-glow").search_hash({
		animation = {
			animation_type = "strobe",
		},
	})
end, { desc = "Search hash with highlight", noremap = true })

vim.keymap.set({ "n", "x" }, "gc", function()
	-- This is an implementation to preserve the cursor position
	local pos = vim.fn.getpos(".")
	vim.schedule(function()
		vim.fn.setpos(".", pos)
	end)
	return require("undo-glow").comment()
end, { desc = "Toggle comment with highlight", expr = true, noremap = true })

vim.keymap.set("o", "gc", function()
	require("undo-glow").comment_textobject()
end, { desc = "Comment textobject with highlight", noremap = true })

vim.keymap.set("n", "gcc", function()
	return require("undo-glow").comment_line()
end, { desc = "Toggle comment line with highlight", expr = true, noremap = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	callback = function()
		require("undo-glow").yank()
	end,
})

-- This only handles neovim instance and do not highlight when switching panes in tmux
vim.api.nvim_create_autocmd("CursorMoved", {
	desc = "Highlight when cursor moved significantly",
	callback = function()
		require("undo-glow").cursor_moved({
			animation = {
				animation_type = "slide",
			},
		})
	end,
})

-- This will handle highlights when focus gained, including switching panes in tmux
vim.api.nvim_create_autocmd("FocusGained", {
	desc = "Highlight when focus gained",
	callback = function()
		---@type UndoGlow.CommandOpts
		local opts = {
			animation = {
				animation_type = "slide",
			},
		}

		opts = require("undo-glow.utils").merge_command_opts("UgCursor", opts)
		local pos = require("undo-glow.utils").get_current_cursor_row()

		require("undo-glow").highlight_region(vim.tbl_extend("force", opts, {
			s_row = pos.s_row,
			s_col = pos.s_col,
			e_row = pos.e_row,
			e_col = pos.e_col,
			force_edge = opts.force_edge == nil and true or opts.force_edge,
		}))
	end,
})

vim.api.nvim_create_autocmd("CmdlineLeave", {
	desc = "Highlight when search cmdline leave",
	callback = function()
		require("undo-glow").search_cmd({
			animation = {
				animation_type = "fade",
			},
		})
	end,
})
