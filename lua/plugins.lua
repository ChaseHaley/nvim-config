local later = require("later")

-- Loaded up front: anything that affects the first render or must see the
-- first buffer/VimEnter (colorscheme, statusline, syntax, argv handling).
require("plugins/treesitter")
require("plugins/plenary")
-- require("plugins/web-devicons")
require("plugins/mini")
require("plugins/snacks")
require("plugins/lualine")
-- Follows the Omarchy system theme when there is one, otherwise our own
-- tokyonight setup.
if not require("plugins/omarchy-theme").setup() then
	require("plugins/tokyonight")
end
require("plugins/oil")
-- Guesses the indent from a BufRead autocmd its own plugin/ file registers, so
-- it must be on the runtimepath before the argv buffers load
-- require("plugins/guess-indent")
-- Enables itself from a VimEnter autocmd
require("plugins/no-neck-pain")
-- Attaches its LSP through a FileType autocmd, so it must exist before the
-- first ps1 buffer loads
require("plugins/powershell")
-- Not sure why but lazy fails with this
require("plugins/camelCaseMotion")

-- Everything else loads right after startup finishes.
later("plugins/lspconfig")
-- Required by easy-dotnet, causes issues if C# file is accessed before this is loaded
later("plugins/treesitter-textobjects")
later("plugins/treesitter-context")
later("plugins/autocomplete")
later("plugins/indent-line")
later("plugins/lint")
later("plugins/which-key")
later("plugins/dev")
later("plugins/autopairs")
-- later("plugins/todo-comments")
later("plugins/conform")
later("plugins/bufjump")
later("plugins/gitsigns")
later("plugins/comments")
-- later("plugins/grapple")
-- later("plugins/arrow")
-- later("plugins/roslyn")
later("plugins/easy-dotnet", { cond = require("dotnet_project").will_auto_load })
later("plugins/easy-dotnet", { event = "FileType", opts = { pattern = { "cs", "vb", "fsharp", "razor" } } })
later("plugins/easy-dotnet", {
	event = { "BufReadPre", "BufNewFile" },
	opts = { pattern = { "*.sln", "*.slnx", "*.csproj", "*.fsproj" } },
})
later("plugins/lazydotnet", { event = "FileType", opts = { pattern = { "cs", "vb", "fsharp", "razor" } } })
later("plugins/csvview", { event = "FileType", opts = { pattern = { "csv", "tsv" } } })
later("plugins/diffview")
later("plugins/neogit")
later("plugins/flash")
later("plugins/render-markdown", { event = "FileType", opts = { pattern = "markdown" } })
if not vim.g.neovide then
	later("plugins/smear-cursor")
end
later("plugins/toggleterm")
later("plugins/treesj")
later("plugins/undo-glow")
later("plugins/windows")
later("plugins/winshift")
later("plugins/typescript-tools", {
	event = "FileType",
	opts = { pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" } },
})
later("plugins/copilot")
-- later("plugins/sidekick")
later("plugins/trouble")
later("plugins/wezterm-types", {
	event = "FileType",
	opts = {
		pattern = {
			"lua"
		}
	}
})
later("plugins/vim-matchup")
later("plugins/nvim-ts-autotag", {
	event = "FileType",
	opts = {
		pattern = {
			"typescript",
			"javascript",
			"typescriptreact",
			"javascriptreact",
			"xml",
			"html",
			"templ",
			"php",
			"razor",
		},
	},
})
-- later("plugins/fyler")
-- The vault lives on the Windows machine
if vim.fn.has("win32") == 1 then
	later("plugins/obsidian")
end
later("plugins/pretty_hover")

if vim.g.neovide then
	later("plugins/tabby")
	later("plugins/scope")
end
later("plugins/resession")
-- later("plugins/mssql")
