-- Copy to lua/local.lua (gitignored) and keep only what this machine needs.
require("loadout").machine({
	-- Entries or groups from lua/plugins.lua.
	disable = { "dotnet", "plugins/smear-cursor" },
	-- Entries marked opt_in in lua/plugins.lua.
	enable = { "plugins/dms" },
})

-- Obsidian loads only when a vault is set.
vim.g.obsidian_vault = "C:\\Users\\me\\Obsidian\\Main"
