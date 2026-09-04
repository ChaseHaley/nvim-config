-- Copy to lua/local.lua (gitignored) and keep only what this machine needs.
local smartload = require("smartload")

-- A bundle from smartload.bundles, or a single module.
smartload.disable("dotnet")
smartload.disable("plugins/copilot")

-- Obsidian loads only when a vault is set.
vim.g.obsidian_vault = "C:\\Users\\me\\Obsidian\\Main"
