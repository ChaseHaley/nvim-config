local now = require("../now")
now("plugins/unnest")
vim.pack.add({ "https://github.com/folke/snacks.nvim" })
require("snacks").setup(
	---@type snacks.Config
	{
	-- your configuration comes here
	-- or leave it empty to use the default settings
	-- refer to the configuration section below
	bigfile = { enabled = true },
	dashboard = { enabled = false },
	explorer = { enabled = false },
	indent = { enabled = false },
	input = { enabled = true },
	image = { enabled = true },
	lazygit = {
		enabled = false,
		-- The default "nvim-remote" editPreset emits POSIX shell syntax
		-- (`[ -z "$NVIM" ] && ...`), which lazygit runs via `cmd /c` on Windows.
		-- cmd can't parse `[ -z ... ]` (hence `[: missing ']'`) and won't expand
		-- `$NVIM`. Since snacks always launches lazygit from within Neovim, $NVIM
		-- is always set, so we drop the conditional and use cmd-compatible commands
		-- with `%NVIM%`.
		-- config = {
		-- 	os = {
		-- 		editPreset = "nvim",
		-- 	},
		-- },
	},
	notifier = { enabled = false },
	picker = {
		enabled = true,
		layout = {
			-- fullscreen = true,
			reverse = true,
			layout = {
				box = "horizontal",
				backdrop = false,
				width = 0.8,
				height = 0.8,
				border = "none",
				{
					box = "vertical",
					{ win = "list", title = " Results ", title_pos = "center", border = true },
					{
						win = "input",
						height = 1,
						border = true,
						title = "{title} {live} {flags}",
						title_pos = "center",
					},
				},
				{
					win = "preview",
					title = "{preview:Preview}",
					width = 0.5,
					border = true,
					title_pos = "center",
				},
			},
		},
		db = {
			sqlite3_path = vim.env.LIBSQLITE,
		},
	},
	quickfile = { enabled = false },
	scope = { enabled = false },
	scroll = {
		-- enabled = not vim.g.neovide,
		enabled = false,
		animate = {
			duration = { step = 10, total = 50 },
			easing = "linear",
		},
		-- faster animation when repeating scroll after delay
		animate_repeat = {
			delay = 20, -- delay in ms before using the repeat animation
			duration = { step = 5, total = 50 },
			easing = "linear",
		},
		-- what buffers to animate
		filter = function(buf)
			return vim.g.snacks_scroll ~= false
				and vim.b[buf].snacks_scroll ~= false
				and vim.bo[buf].buftype ~= "terminal"
		end,
	},
	statuscolumn = { enabled = false },
	words = { enabled = false },
})

-- MonkeyPatch - https://github.com/folke/snacks.nvim/pull/2012
local M = require("snacks.picker.core.main")
M.new = function(opts)
	opts = vim.tbl_extend("force", {
		float = false,
		file = true,
		current = false,
	}, opts or {})
	local self = setmetatable({}, M)
	self.opts = opts
	self.win = vim.api.nvim_get_current_win()
	return self
end

-- Formatters that call Snacks.picker.format.filename, so a path line has something to say.
local path_line_formats = {
	buffer = true,
	diagnostic = true,
	file = true,
	git_status = true,
}

---@param opts snacks.picker.Config?
local function has_path_line(opts)
	return opts ~= nil and path_line_formats[opts.format] == true
end

-- snacks renders one buffer line per item and replaces newlines with spaces, so a
-- second line is only reachable through a virt_lines extmark. Anything whose [1] is
-- not a string is passed through to nvim_buf_set_extmark untouched. Every item of a
-- two line picker gets one, empty when it has no file, so each takes the same rows.
local picker_config = require("snacks.picker.config")
local resolve_format = picker_config.format
picker_config.format = function(opts)
	local format = resolve_format(opts)
	if not has_path_line(opts) then
		return format
	end
	if opts.formatters and opts.formatters.file then
		opts.formatters.file.filename_only = true
	end
	return function(item, picker)
		local line = format(item, picker)
		line[#line + 1] = {
			col = 0,
			virt_lines = { { { item.file and "   " .. vim.fn.fnamemodify(item.file, ":.") or "", "SnacksPickerDir" } } },
		}
		return line
	end
end

-- snacks sets state.height to the window height in text lines, writes state.height + 1
-- buffer lines (the last always blank) and pins topline to 1, so it never accounts for
-- the screen row each virt_line adds. Fit half as many items, and keep the slots the
-- items do not use, so the blank trailing line falls past the bottom of the window
-- rather than under the list, which is where reverse puts it.
local List = require("snacks.picker.core.list")
local list_render = List.render
local list_height = List.height

---@param self snacks.picker.list
local function is_two_line(self)
	return self.win:win_valid() and has_path_line(self.picker and self.picker.opts)
end

function List:height()
	if not is_two_line(self) then
		return list_height(self)
	end
	local rows = vim.api.nvim_win_get_height(self.win.win)
	return math.max(1, math.min(self:count(), math.floor(rows / 2)))
end

function List:render()
	if is_two_line(self) then
		local slots = math.max(1, vim.api.nvim_win_get_height(self.win.win) - self:height())
		if self.state.height ~= slots then
			self.state.height = slots
			self.dirty = true
		end
	end
	return list_render(self)
end

vim.keymap.set("n", "<leader>sh", function()
	require("snacks").picker.help()
end, { desc = "[S]earch [H]elp" })

vim.keymap.set("n", "<leader>sk", function()
	require("snacks").picker.keymaps()
end, { desc = "[S]earch [K]eymaps" })

vim.keymap.set("n", "<leader>sf", function()
	require("snacks").picker.smart()
end, { desc = "[S]earch [F]iles" })

vim.keymap.set("n", "<leader>sF", function()
	require("snacks").picker.files()
end, { desc = "[S]earch [F]iles" })

vim.keymap.set("n", "<leader>sp", function()
	require("snacks").picker.pickers()
end, { desc = "[S]earch [P]ickers" })

vim.keymap.set("n", "<leader>su", function()
	require("snacks").picker.undo()
end, { desc = "[S]earch [U]ndo" })

vim.keymap.set({ "n", "x" }, "<leader>sw", function()
	require("snacks").picker.grep_word()
end, { desc = "[S]earch current [W]ord" })

vim.keymap.set("n", "<leader>sg", function()
	require("snacks").picker.grep()
end, { desc = "[S]earch by [G]rep" })

vim.keymap.set("n", "<leader>sde", function()
	require("snacks").picker.diagnostics({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "[S]earch [D]iagnostic [E]rrors" })

vim.keymap.set("n", "<leader>sdw", function()
	require("snacks").picker.diagnostics({ severity = vim.diagnostic.severity.WARN })
end, { desc = "[S]earch [D]iagnostic [W]arnings" })

vim.keymap.set("n", "<leader>sdd", function()
	require("snacks").picker.diagnostics()
end, { desc = "[S]earch [DD]iagnostic All" })

vim.keymap.set("n", "<leader>sr", function()
	require("snacks").picker.resume()
end, { desc = "[S]earch [R]esume" })

vim.keymap.set("n", "<leader>s.", function()
	require("snacks").picker.recent()
end, { desc = '[S]earch Recent Files ("." for repeat)' })

vim.keymap.set("n", "<leader><leader>", function()
	require("snacks").picker.buffers()
end, { desc = "[ ] Find existing buffers" })

vim.keymap.set("n", "<leader>sm", function()
	require("snacks").picker.marks()
end, { desc = "[S]earch [M]arks" })

vim.keymap.set("n", "<leader>/", function()
	require("snacks").picker.lines()
end, { desc = "[/] Fuzzily search in current buffer" })

vim.keymap.set("n", "<leader>s/", function()
	require("snacks").picker.grep_buffers()
end, { desc = "[S]earch [/] in Open Files" })

vim.keymap.set("n", "<leader>sn", function()
	require("snacks").picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "[S]earch [N]eovim files" })

vim.keymap.set("n", "<leader>sc", function()
	require("snacks").picker.files({ cwd = vim.fn.expand("~/.claude"), hidden = true, ignored = false })
end, { desc = "[S]earch [C]laude files" })

vim.keymap.set("n", "<leader>sa", function()
	require("snacks").picker.files({ cwd = vim.fn.getcwd() .. "/.claude/local", hidden = true, ignored = true })
end, { desc = "[S]earch AI files" })

vim.keymap.set("n", "<leader>sx", function()
	require("snacks").picker.git_status()
end, { desc = "[S]earch git status" })

vim.keymap.set("n", "<leader>s;", function()
	require("snacks").picker.spelling()
end, { desc = "[S]earch spelling" })

vim.keymap.set("n", "<leader>sb", function()
	require("snacks").picker.git_branches()
end, { desc = "[S]earch git branches" })
