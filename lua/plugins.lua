local later = require("later")

-- Loaded up front: anything that affects the first render or must see the
-- first buffer/VimEnter (colorscheme, statusline, syntax, argv handling).
require("plugins/treesitter")
require("plugins/plenary")
-- require("plugins/web-devicons")
require("plugins/mini")
require("plugins/snacks")
require("plugins/tokyonight")
-- require("plugins/dev")
require("plugins/oil")
require("plugins/guess-indent")
require("plugins/indent-line")
require("plugins/no-neck-pain")
-- Attaches its LSP through a FileType autocmd, so it must exist before the
-- first ps1 buffer loads
require("plugins/powershell")
-- Not sure why but lazy fails with this
require("plugins/camelCaseMotion")

-- Required by DAP
require("plugins/lspconfig")
-- Required by easy-dotnet, causes issues if C# file is accessed before this is loaded 
require("plugins/dap")

-- Everything else loads right after startup finishes.
require("plugins/treesitter-textobjects")
require("plugins/treesitter-context")
require("plugins/autocomplete")
require("plugins/lint")
require("plugins/which-key")
require("plugins/autopairs")
-- require("plugins/todo-comments")
require("plugins/conform")
require("plugins/bufjump")
require("plugins/gitsigns")
require("plugins/comments")
-- later("plugins/grapple")
-- later("plugins/arrow")
-- later("plugins/roslyn")
later("plugins/easy-dotnet", { event = "FileType", opts = { pattern = { "cs", "vb", "fsharp", "razor" } } })
later("plugins/easy-dotnet", {
	event = { "BufReadPre", "BufNewFile" },
	opts = { pattern = { "*.sln", "*.slnx", "*.csproj", "*.fsproj" } },
})
later("plugins/lazydotnet", { event = "FileType", opts = { pattern = { "cs", "vb", "fsharp", "razor" } } })
later("plugins/csvview", { event = "FileType", opts = { pattern = { "csv", "tsv" } } })
require("plugins/diffview")
require("plugins/neogit")
require("plugins/flash")
later("plugins/render-markdown", { event = "FileType", opts = { pattern = "markdown" } })
if not vim.g.neovide then
	require("plugins/smear-cursor")
end
require("plugins/toggleterm")
require("plugins/treesj")
require("plugins/undo-glow")
require("plugins/windows")
require("plugins/winshift")
later("plugins/typescript-tools", {
	event = "FileType",
	opts = { pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" } },
})
require("plugins/copilot")
-- require("plugins/sidekick")
require("plugins/trouble")
later("plugins/wezterm-types", {
	event = "FileType",
	opts = {
		pattern = {
			"lua"
		}
	}
})
require("plugins/vim-matchup")
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
require("plugins/obsidian")
require("plugins/pretty_hover")

if vim.g.neovide then
	require("plugins/tabby")
	require("plugins/scope")
end
require("plugins/resession")
-- require("plugins/mssql")
