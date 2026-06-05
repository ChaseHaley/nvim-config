vim.pack.add({ gh("echasnovski/mini.nvim") })
require("mini.ai").setup({
	n_lines = 500,
	-- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
	-- mappings = {
	-- 	around_next = "aa",
	-- 	inside_next = "ii",
	-- },
})
require("mini.surround").setup({})
require("mini.icons").setup({})
require("mini.move").setup({})
-- Simple and easy statusline.
--  You could remove this setup call if you don't like it,
--  and try some other statusline plugin
local statusline = require("mini.statusline")
-- set use_icons to true if you have a Nerd Font
statusline.setup({ use_icons = vim.g.have_nerd_font })

-- You can configure sections in the statusline by overriding their
-- default behavior. For example, here we set the section for
-- cursor location to LINE:COLUMN
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function()
	return "%2l:%-2v"
end

---@diagnostic disable-next-line: duplicate-set-field
statusline.section_filename = function(args)
	-- In terminal always use plain name
	-- if vim.bo.buftype == 'terminal' then
	-- 	return '%t'
	return "%f%m%r"
end
-- Disable mini indent for certain things
-- Copied for LazyVim
vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"Trouble",
		"alpha",
		"dashboard",
		"fzf",
		"help",
		"lazy",
		"mason",
		"neo-tree",
		"notify",
		"snacks_dashboard",
		"snacks_notif",
		"snacks_terminal",
		"snacks_win",
		"toggleterm",
		"trouble",
	},
	callback = function()
		vim.b.miniindentscope_disable = true
	end,
})
