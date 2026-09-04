-- Copy to <project>/.nvim.lua. Neovim asks to trust the file on first load.
-- Keep it out of shared repos: add .nvim.lua to the global git ignore.
local lazyload = require("lazyload")

-- A bundle from lazyload.bundles, or a single module, off for this project.
lazyload.disable("dotnet")

-- A module this project needs that plugins.lua does not load.
require("later")("plugins/mssql")

-- Runs after every plugin's setup(), for state a plugin only exposes then.
lazyload.on_override(function()
	vim.o.makeprg = "npm run build"
end)
