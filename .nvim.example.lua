-- Copy to <project>/.nvim.lua. Neovim asks to trust the file on first load.
-- Keep it out of shared repos: add .nvim.lua to the global git ignore.
require("loadout").project({
	-- Entries or groups from lua/plugins.lua, off for this project.
	disable = { "dotnet" },
	-- Entries this project needs that lua/plugins.lua does not list.
	load = { "plugins/mssql" },
	-- Runs after every plugin's setup(), for state a plugin only exposes then.
	after = function()
		vim.o.makeprg = "npm run build"
	end,
})
