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
