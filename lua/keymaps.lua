-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/Tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- vim: ts=2 sts=2 sw=2 et
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

vim.keymap.set({ "x", "n" }, "<leader>zp", '"_dP', { desc = "Put and keep registry" })
vim.keymap.set("n", "gq", "<Cmd>tabc<CR>", { desc = "Close tab" })

vim.keymap.set("x", "<leader>z/", "<C-\\><C-n>`</\\%V", { desc = "Search forward within visual selection" })
vim.keymap.set("x", "<leader>z?", "<C-\\><C-n>`>?\\%V", { desc = "Search backward within visual selection" })

vim.keymap.set("n", "<leader>tl", function ()
	vim.o.relativenumber = not vim.o.relativenumber
end, { desc = "[T]oggle Relative [L]ine Numbers" })

-- Grab everything up to and including the ".razor" or ".cshtml" extension as the base name.
local function razor_base(file)
	return file:match("^(.*%.razor)") or file:match("^(.*%.cshtml)")
end

-- Switch to a companion Razor/cshtml file by target suffix.
-- Works from any .razor / .razor.cs / .razor.js / .razor.css / .cshtml / .cshtml.cs file.
local function razor_switch(target)
	local file = vim.fn.expand("%:p")

	local base = razor_base(file)
	if not base then
		vim.notify("Not a .razor/.cshtml family file", vim.log.levels.WARN)
		return
	end

	local dest = base .. target
	if dest == file then
		vim.notify("Already editing this file", vim.log.levels.INFO)
	elseif vim.fn.filereadable(dest) == 1 then
		vim.cmd.edit(vim.fn.fnameescape(dest))
	else
		vim.notify("Companion file not found: " .. vim.fn.fnamemodify(dest, ":t"), vim.log.levels.WARN)
	end
end

-- Cycle to the next existing companion file in a fixed order.
-- .cshtml files only ever have "" and ".cs" companions; .js/.css are skipped since they don't exist.
local razor_cycle_order = { "", ".cs", ".js", ".css" }
local function razor_cycle()
	local file = vim.fn.expand("%:p")

	local base = razor_base(file)
	if not base then
		vim.notify("Not a .razor/.cshtml family file", vim.log.levels.WARN)
		return
	end

	-- Find where the current file sits in the cycle order.
	local current = file:sub(#base + 1)
	local start
	for i, suffix in ipairs(razor_cycle_order) do
		if suffix == current then
			start = i
			break
		end
	end
	if not start then
		return
	end

	-- Walk the remaining suffixes cyclically and edit the first one that exists.
	local count = #razor_cycle_order
	for offset = 1, count - 1 do
		local suffix = razor_cycle_order[(start - 1 + offset) % count + 1]
		local dest = base .. suffix
		if vim.fn.filereadable(dest) == 1 then
			vim.cmd.edit(vim.fn.fnameescape(dest))
			return
		end
	end
end

-- Only register the Razor switch keymaps while editing a .razor or .cshtml family file.
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	group = vim.api.nvim_create_augroup("razor-switch-keymaps", { clear = true }),
	pattern = { "*.razor*", "*.cshtml*" },
	callback = function(args)
		local opts = { buffer = args.buf }
		vim.keymap.set("n", "<leader>rr", function()
			razor_switch("")
		end, vim.tbl_extend("force", opts, { desc = "Razor/cshtml: switch to base file" }))
		vim.keymap.set("n", "<leader>rc", function()
			razor_switch(".cs")
		end, vim.tbl_extend("force", opts, { desc = "Razor/cshtml: switch to .cs" }))
		vim.keymap.set("n", "<leader>rs", function()
			razor_switch(".css")
		end, vim.tbl_extend("force", opts, { desc = "Razor: switch to .razor.css" }))
		vim.keymap.set("n", "<leader>rj", function()
			razor_switch(".js")
		end, vim.tbl_extend("force", opts, { desc = "Razor: switch to .razor.js" }))
		vim.keymap.set("n", "<leader>r<leader>", razor_cycle, vim.tbl_extend("force", opts, { desc = "Razor/cshtml: cycle companion files" }))
	end,
})

-- Yank/put with OS clipboard
vim.keymap.set({ "n", "x" }, "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')
vim.keymap.set({ "n", "x" }, "<leader>p", '"+p')
vim.keymap.set({ "n", "x" }, "<leader>P", '"+P')

local function validateExecutable(executable)
	local valid = true
	if vim.fn.executable(executable) == 0 then
		vim.notify(executable .. " not found on PATH")
		valid = false
	end

	return valid
end

local function getCurrentFile()
	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("No file in current buffer")
		return nil
	end

	return file
end

vim.keymap.set("n", "<leader>zov", function()
	local executable = "devenv"
	validateExecutable(executable)
	local file = getCurrentFile()

	if file ~= nil then
		vim.system({
			executable,
			"/Edit",
			file,
		}, { detach = true })
	end
end, { desc = "Open file in Visual Studio" })

vim.keymap.set("n", "<leader>zoc", function()
	local executable = "code"
	validateExecutable(executable)
	local file = getCurrentFile()

	if file ~= nil then
		vim.system({
			vim.fn.exepath(executable) ~= "" and vim.fn.exepath(executable) or executable,
			file,
		}, { detach = true })
	end
end, { desc = "Open file in VSCode" })

vim.keymap.set("n", "<leader>zoz", function()
	local executable = "zed"
	validateExecutable(executable)
	local file = getCurrentFile()

	if file ~= nil then
		vim.system({
			vim.fn.exepath(executable) ~= "" and vim.fn.exepath(executable) or executable,
			file,
		}, { detach = true })
	end
end, { desc = "Open file in Zed" })

vim.keymap.set("n", "<leader>zof", function()
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" then
		vim.notify("Current buffer has no file path", vim.log.levels.WARN)
		return
	end

	local dir = vim.fn.fnamemodify(file, ":p:h")
	vim.ui.open(dir)
end, { desc = "Open file directory in file manger"})

-- Claude Code resolves "@" references against the cwd it was launched in, which is normally
-- the repository root rather than Neovim's cwd. Absolute paths also resolve, but on Windows
-- the drive colon makes Claude Code additionally parse the mention as an MCP resource
-- reference ("C" as the server name), which fails and is discarded.
local function agent_mention_path(absolute)
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" then
		vim.notify("Current buffer has no file path", vim.log.levels.WARN)
		return nil
	end

	if absolute then
		return vim.fs.normalize(file)
	end

	local root = vim.fs.root(file, ".git") or vim.fn.getcwd()
	return vim.fs.relpath(root, file) or vim.fs.normalize(file)
end

local function copy_agent_mention(absolute, suffix)
	local path = agent_mention_path(absolute)
	if not path then
		return
	end

	local mention = "@" .. path .. (suffix or "")
	vim.fn.setreg("+", mention)
	vim.notify("Copied " .. mention)
end

-- line("v") gives the far end of the visual selection, or the cursor outside visual mode.
local function line_suffix()
	local from, to = vim.fn.line("v"), vim.fn.line(".")
	if from > to then
		from, to = to, from
	end

	return from == to and ("#L%d"):format(from) or ("#L%d-%d"):format(from, to)
end

vim.keymap.set("n", "<leader>zaf", function()
	copy_agent_mention(false)
end, { desc = "Copy [A]gent mention: [F]ile" })

vim.keymap.set("n", "<leader>zaF", function()
	copy_agent_mention(true)
end, { desc = "Copy [A]gent mention: [F]ile, absolute" })

vim.keymap.set({ "n", "x" }, "<leader>zal", function()
	copy_agent_mention(false, line_suffix())
end, { desc = "Copy [A]gent mention: [L]ines" })

vim.keymap.set({ "n", "x" }, "<leader>zaL", function()
	copy_agent_mention(true, line_suffix())
end, { desc = "Copy [A]gent mention: [L]ines, absolute" })
