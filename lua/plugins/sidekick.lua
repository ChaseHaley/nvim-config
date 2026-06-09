-- NOTE: Depends on:
-- snacks.nvim
-- nvim-treesitter-textobjects
-- copilot.lua
vim.pack.add({ gh("folke/sidekick.nvim") })

--- @type sidekick.Config
local opts = {
	-- add any options here
	cli = {
		mux = {
			enabled = false,
		},
	},
	nes = {
		enabled = false,
	},
}
require("sidekick").setup(opts)
local nes = require('sidekick.nes');

vim.g.disable_nes = true

local function disableNes()
	if vim.g.disable_nes == true and nes.enabled == true then
		nes.enable(false)
	end
end

vim.keymap.set("n", "<leader>an", function()
	if nes.enabled then
		nes.enable(false)
	else
		nes.enable(true)
	end
end, { desc = "Toggle NES" })

-- Goes to or applies next edit suggestion
vim.keymap.set("n", "<tab>", function()
	-- if there is a next edit, jump to it, otherwise apply it if any
	if not require("sidekick").nes_jump_or_apply() then
		return "<Tab>" -- fallback to normal tab
	end
end, { expr = true, desc = "Goto/Apply Next Edit Suggestion" })

-- Focuses sidekick
vim.keymap.set({ "n", "t", "i", "x" }, "<M-.>", function()
	require("sidekick.cli").focus()
end, { desc = "Sidekick Focus" })

-- Toggles sidekick cli
vim.keymap.set("n", "<leader>aa", function()
	require("sidekick.cli").toggle()
end, { desc = "Sidekick Toggle CLI" })

-- Selects a CLI tool
vim.keymap.set("n", "<leader>as", function()
	require("sidekick.cli").select()
	-- Or to select only installed tools:
	-- require("sidekick.cli").select({ filter = { installed = true } })
end, { desc = "Select CLI" })

vim.keymap.set("n", "<leader>ad", function()
	require("sidekick.cli").close()
end, { desc = "Close CLI Session" })

vim.keymap.set({ "x", "n" }, "<leader>at", function()
	require("sidekick.cli").send({ msg = "{this}" })
end, { desc = "Send This" })

vim.keymap.set("n", "<leader>af", function()
	require("sidekick.cli").send({ msg = "{file}" })
end, { desc = "Send File" })

vim.keymap.set("x", "<leader>av", function()
	require("sidekick.cli").send({ msg = "{selection}" })
end, { desc = "Send Visual Selection" })

vim.keymap.set({ "n", "x" }, "<leader>ap", function()
	require("sidekick.cli").prompt()
end, { desc = "Sidekick Select Prompt" })

-- Example of a keybinding to open Claude directly
vim.keymap.set("n", "<leader>ac", function()
	require("sidekick.cli").toggle({ name = "claude", focus = true })
end, { desc = "Sidekick Toggle Claude" })
