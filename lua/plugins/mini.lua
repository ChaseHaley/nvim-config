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

-- Per-section flash: returns `flash_group` for `dur` ms after `value` changes,
-- then reverts to `normal_hl`. Swaps highlight-group names instead of mutating
-- colors, so it survives colorscheme reloads. Forces a delayed redrawstatus so
-- the revert happens even when the statusline is otherwise idle.
local flash_state = {}
local function flash_hl(id, value, normal_hl, flash_group, dur)
	dur = dur or 5000
	local st = flash_state[id]
	if not st or st.value ~= value then
		flash_state[id] = { value = value, until_ms = vim.uv.now() + dur }
		vim.defer_fn(vim.cmd.redrawstatus, dur)
		return flash_group
	end
	if vim.uv.now() < st.until_ms then
		return flash_group
	end
	return normal_hl
end

-- set use_icons to true if you have a Nerd Font
statusline.setup({
	use_icons = vim.g.have_nerd_font,
	content = {
		active = function()
			local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
			local git = statusline.section_git({ trunc_width = 40 })
			local diagnostics = statusline.section_diagnostics({ trunc_width = 75 })
			local filename = statusline.section_filename({ trunc_width = 140 })
			local fileinfo = statusline.section_fileinfo({ trunc_width = 120 })
			local location = statusline.section_location()

			local nes_ok, nes = pcall(require, "sidekick.nes")
			local nes_status = nes_ok and nes.enabled
			local easy_dotnet_ok, easy_dotnet = pcall(require, 'easy-dotnet')
			local startup_project = (easy_dotnet_ok and easy_dotnet.lualine.jobs())

			return statusline.combine_groups({
				{ hl = mode_hl, strings = { mode } },
				{
					hl = nes_status and "MiniStatusNesEnabled" or "MiniStatusNesDisabled",
					strings = { "NES" },
				},
				{ hl = "MiniStatuslineDevinfo", strings = { git, diagnostics } },
				"%<", -- truncate point
				{
					hl = flash_hl("filename", vim.fn.expand("%:."), "MiniStatuslineFilename", "MiniStatuslineFilenameFlash", 1000),
					strings = { filename },
				},
				"%=", -- right align after this
				{ hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
				{ hl = mode_hl, strings = { location } },
				{ hl = "MiniStatusStartupProject", strings = { startup_project } },
			})
		end,
	},
})

-- You can configure sections in the statusline by overriding their
-- default behavior. For example, here we set the section for
-- cursor location to LINE:COLUMN
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function()
	return "%2l:%-2v"
end

---@diagnostic disable-next-line: duplicate-set-field
statusline.section_filename = function()
	-- In terminal always use plain name
	-- if vim.bo.buftype == 'terminal' then
	-- 	return '%t'
	return "%f%m%r"
end

-- Flash group for filename changes (gold); selected by flash_hl in active().
vim.api.nvim_set_hl(0, "MiniStatuslineFilenameFlash", { fg = "#bb9af7", bold = true })
vim.api.nvim_set_hl(0, 'MiniStatusNesEnabled', { fg = '#9ece6a', bold = true })
vim.api.nvim_set_hl(0, 'MiniStatusNesDisabled', { fg = '#f7768e', bold = true })
vim.api.nvim_set_hl(0, 'MiniStatusStartupProject', { bg = '#7aa2f7', bold = true })

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
