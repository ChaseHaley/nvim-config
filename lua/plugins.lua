local function is_neovide()
	return vim.g.neovide == true
end

local dotnet_filetypes = { "cs", "vb", "fsharp", "razor" }
local js_filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" }

require("loadout").load({
	-- Loaded up front: anything that affects the first render or must see the
	-- first buffer/VimEnter (colorscheme, statusline, syntax, argv handling).
	{ "plugins/treesitter", now = true, vscode = true },
	-- Follows the Omarchy system theme when there is one, otherwise our own
	-- tokyonight setup.
	{
		"plugins/colorschemes",
		now = true,
		cond = function()
			return not require("plugins/omarchy-theme").setup()
		end,
	},
	{ "plugins/plenary", now = true },
	-- { "plugins/web-devicons", now = true },
	{ "plugins/mini", now = true, vscode = true },
	{ "plugins/unnest", now = true },
	{ "plugins/snacks", now = true },
	{ "plugins/lualine", now = true },
	{ "plugins/oil", now = true },
	-- Guesses the indent from a BufRead autocmd its own plugin/ file registers, so
	-- it must be on the runtimepath before the argv buffers load
	-- { "plugins/guess-indent", now = true },
	-- Enables itself from a VimEnter autocmd
	{ "plugins/no-neck-pain", now = true },
	-- Attaches its LSP through a FileType autocmd, so it must exist before the
	-- first ps1 buffer loads
	{ "plugins/powershell", now = true },
	-- Not sure why but lazy fails with this
	{ "plugins/camelCaseMotion", now = true, vscode = true },

	-- Everything else loads right after startup finishes.
	{ "plugins/lspconfig" },
	-- Required by easy-dotnet, causes issues if C# file is accessed before this is loaded
	{ "plugins/treesitter-textobjects", vscode = true },
	{ "plugins/treesitter-context" },
	{ "plugins/autocomplete" },
	{ "plugins/indent-line" },
	{ "plugins/lint" },
	{ "plugins/which-key" },
	{ "plugins/dev" },
	{ "plugins/autopairs" },
	-- { "plugins/todo-comments" },
	{ "plugins/conform" },
	{ "plugins/bufjump" },
	{ "plugins/gitsigns" },
	{ "plugins/comments" },
	-- { "plugins/grapple" },
	-- { "plugins/arrow" },
	-- { "plugins/roslyn", group = "dotnet" },
	{
		"plugins/easy-dotnet",
		group = "dotnet",
		deps = { "plugins/dap" },
		startup = require("dotnet_project").will_auto_load,
		ft = dotnet_filetypes,
		event = { "BufReadPre", "BufNewFile" },
		pattern = { "*.sln", "*.slnx", "*.csproj", "*.fsproj" },
	},
	{ "plugins/lazydotnet", group = "dotnet", ft = dotnet_filetypes },
	{ "plugins/csvview", ft = { "csv", "tsv" } },
	{ "plugins/diffview" },
	{ "plugins/neogit" },
	{ "plugins/flash", vscode = true },
	{ "plugins/render-markdown", ft = "markdown" },
	{
		"plugins/smear-cursor",
		cond = function()
			return not is_neovide()
		end,
	},
	{ "plugins/toggleterm" },
	{ "plugins/treesj", vscode = true },
	{ "plugins/undo-glow" },
	{ "plugins/windows" },
	{ "plugins/winshift" },
	{ "plugins/typescript-tools", ft = js_filetypes },
	-- { "plugins/copilot" },
	-- { "plugins/sidekick" },
	{ "plugins/trouble" },
	{ "plugins/wezterm-types", ft = "lua" },
	{ "plugins/vim-matchup", vscode = true },
	{
		"plugins/nvim-ts-autotag",
		ft = vim.list_extend({ "xml", "html", "templ", "php", "razor" }, js_filetypes),
	},
	{ "plugins/fyler" },
	{
		"plugins/obsidian",
		cond = function()
			return vim.g.obsidian_vault ~= nil
		end,
	},
	{ "plugins/pretty_hover" },
	{ "plugins/tabby", cond = is_neovide },
	{ "plugins/scope", cond = is_neovide },
	{ "plugins/resession" },
	{ "plugins/genghis" },
	-- { "plugins/mssql" },
	{ "plugins/dms", opt_in = true },
})
