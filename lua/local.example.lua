-- Copy to lua/local.lua (gitignored) and keep only what this machine needs.
local lazyload = require("lazyload")

-- A bundle from lazyload.bundles, or a single module.
lazyload.disable("dotnet")
lazyload.disable("plugins/copilot")

-- Obsidian loads only when a vault is set.
vim.g.obsidian_vault = "C:\\Users\\me\\Obsidian\\Main"
