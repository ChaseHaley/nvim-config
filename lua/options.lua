-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

vim.o.exrc = true -- load .nvim.lua / .nvimrc / .exrc from cwd
vim.o.secure = true -- restrict dangerous commands in local configs

-- Make line numbers default
vim.o.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.o.relativenumber = true

vim.o.swapfile = false

-- Disable text wrapping
-- Generally speaking, if text is wrapping then the line is too long
-- or I'm working in too small of an editor and this can be manually enabled for that session
vim.o.wrap = false

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
-- vim.schedule(function()
-- 	vim.o.clipboard = "unnamedplus"
-- end)

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
--
--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-options-guide`
vim.o.list = false
-- vim.o.listchars = {
-- 	tab = '» ',
-- 	trail = '·',
-- 	nbsp = '␣',
-- }

-- Preview substitutions live, as you type!
vim.o.inccommand = "split"

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 5
vim.o.sidescrolloff = 20

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- Tab settings
-- This option, when enabled, causes Neovim to insert spaces instead of actual tab characters when you press the Tab key. To use tabs, you must disable it.
vim.o.expandtab = false
local tabSize = 4
-- This defines the visual width of a tab character. While it doesn't directly control whether tabs or spaces are used for indentation, it's crucial for consistent display.
vim.o.tabstop = tabSize
-- This option controls the number of spaces (or tab characters, if noexpandtab is set) used for auto-indentation and the >> and << commands.
vim.o.shiftwidth = tabSize
-- This option makes the Tab key behave as if tabs were set to a different value, allowing you to insert or delete a specific number of spaces or tabs with the Tab and Backspace keys.
vim.o.softtabstop = tabSize

vim.o.autoindent = true
vim.o.smartindent = true

-- Ensure specific filetypes use tabs
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "css", "scss", "sass", "javascript", "typescript", "html", "vue", "jsx", "tsx" },
	callback = function()
		vim.bo.expandtab = false
		vim.bo.tabstop = 4
		vim.bo.shiftwidth = 4
		vim.bo.softtabstop = 4
	end,
})

-- Disable concealing for JSON files to always show quotes
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "json", "jsonc" },
	callback = function()
		vim.opt_local.conceallevel = 0
	end,
})

vim.o.spell = true
vim.o.spelllang = "en_us"
vim.o.spelloptions = "camel"
vim.o.spellsuggest = "best"

-- vim.o.foldmethod = 'indent'
vim.o.foldmethod = "marker"
vim.o.foldmarker = "#region,#endregion"
vim.o.conceallevel = 1
vim.o.foldlevel = 99

-- vim.opt.diffopt = vim.opt.diffopt + "algorithm:histogram"

-- Use PowerShell for :make, :! etc. On Linux the default shell already handles
-- these, and overriding it breaks anything that shells out expecting POSIX sh.
if vim.fn.has("win32") == 1 then
	vim.o.shell = "pwsh" -- or "powershell"
	vim.o.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
	vim.o.shellquote = ""
	vim.o.shellxquote = ""

	-- >>> The important part: write to the temp file path Neovim gives (%s)
	vim.o.shellpipe = '2>&1 | Tee-Object -FilePath "%s"'
	vim.o.shellredir = '2>&1 | Out-File -FilePath "%s" -Encoding UTF8'
end

-- TypeScript project build
vim.o.makeprg = "tsc -p tsconfig.json --noEmit --pretty false"

-- Parse: path\file.ts(12,34): error TS1234: Message
vim.o.errorformat = table.concat({
	"%E%f(%l\\,%c): error %m",
	"%W%f(%l\\,%c): warning %m",
	"%-G%.%#",
}, ",")

-- Stop logging that python is not found in Claude/checkhealth
vim.g.loaded_python3_provider = 0

if (vim.g.neovide) then
	vim.o.guifont = "CaskaydiaCove NF:h12"
	vim.g.neovide_scale_factor = 1
	vim.g.neovide_hide_mouse_when_typing = true
end

-- Diagnostic Config & Keymaps
--  See `:help vim.diagnostic.Opts`
vim.diagnostic.config({
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
	underline = { severity = { min = vim.diagnostic.severity.WARN } },

	-- Can switch between these as you prefer
	virtual_text = true, -- Text shows up at the end of the line
	virtual_lines = false, -- Text shows up underneath the line, with virtual lines

	-- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
	jump = {
		on_jump = function(_, bufnr)
			vim.diagnostic.open_float({
				bufnr = bufnr,
				scope = "cursor",
				focus = false,
			})
		end,
	},
})

require("vim._core.ui2").enable({
	enable = true, -- Whether to enable or disable the UI.
	msg = { -- Options related to the message module.
		---@type string|table<string, 'cmd'|'msg'|'pager'> Default message target
		---or table mapping |ui-messages| kinds, triggers and IDs to a target.
		---Table keys are are matched as a Lua pattern to the message ID. 'default'
		---mapping applies to any omitted kind: { default = 'cmd', progress = 'msg' }.
		targets = "cmd",
		cmd = { -- Options related to messages in the cmdline window.
			-- Maximum height (rows if >=1, or % of 'lines' if <1) of messages expanded
			-- beyond 'cmdheight'; 0.999 for full height.
			height = 0.5,
		},
		dialog = { -- Options related to dialog window.
			height = 0.5, -- Maximum height.
		},
		msg = { -- Options related to msg window.
			height = 0.5, -- Maximum height.
			timeout = 4000, -- Time a message is visible in the message window.
		},
		pager = { -- Options related to message window.
			height = 0.999, -- Maximum height.
		},
	},
})
