vim.pack.add({ "https://github.com/brianhuster/unnest.nvim" })
vim.pack.add({ "https://github.com/folke/snacks.nvim" })
require("snacks").setup({
	-- your configuration comes here
	-- or leave it empty to use the default settings
	-- refer to the configuration section below
	bigfile = { enabled = true },
	dashboard = { enabled = false },
	explorer = { enabled = false },
	indent = { enabled = false },
	input = { enabled = false },
	lazygit = {
		enabled = false,
		-- The default "nvim-remote" editPreset emits POSIX shell syntax
		-- (`[ -z "$NVIM" ] && ...`), which lazygit runs via `cmd /c` on Windows.
		-- cmd can't parse `[ -z ... ]` (hence `[: missing ']'`) and won't expand
		-- `$NVIM`. Since snacks always launches lazygit from within Neovim, $NVIM
		-- is always set, so we drop the conditional and use cmd-compatible commands
		-- with `%NVIM%`.
		config = {
			os = {
				editPreset = "nvim",
			},
		},
	},
	notifier = { enabled = true },
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
			sqlite3_path = vim.fn.getenv("LIBSQLITE"),
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

vim.keymap.set("n", "<leader>sh", function()
	require("snacks").picker.help()
end, { desc = "[S]earch [H]elp" })

vim.keymap.set("n", "<leader>sk", function()
	require("snacks").picker.keymaps()
end, { desc = "[S]earch [K]eymaps" })

vim.keymap.set("n", "<leader>sF", function()
	require("snacks").picker.smart({  show_delay = 0 })
end, { desc = "[S]earch [F]iles (snacks)" })

vim.keymap.set("n", "<leader>sp", function()
	require("snacks").picker.pickers()
end, { desc = "[S]earch [P]ickers" })

vim.keymap.set("n", "<leader>su", function()
	require("snacks").picker.undo()
end, { desc = "[S]earch [U]ndo" })

vim.keymap.set({ "n", "x" }, "<leader>sw", function()
	require("snacks").picker.grep_word()
end, { desc = "[S]earch current [W]ord" })

vim.keymap.set("n", "<leader>sG", function()
	require("snacks").picker.grep()
end, { desc = "[S]earch by [G]rep (snacks)" })

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

vim.keymap.set("n", "<leader>sx", function()
	require("snacks").picker.git_status()
end, { desc = "[S]earch git status" })

vim.keymap.set("n", "<leader>s;", function()
	require("snacks").picker.spelling()
end, { desc = "[S]earch spelling" })

vim.keymap.set("n", "<leader>sb", function()
	require("snacks").picker.git_branches()
end, { desc = "[S]earch git branches" })

vim.keymap.set("n", "<leader>sl", function()
	require("snacks").lazygit.open()
end, { desc = "Lazygit" })
