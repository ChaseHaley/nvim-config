-- [[ LSP Configuration ]]
-- Brief aside: **What is LSP?**
--
-- LSP is an initialism you've probably heard, but might not understand what it is.
--
-- LSP stands for Language Server Protocol. It's a protocol that helps editors
-- and language tooling communicate in a standardized fashion.
--
-- In general, you have a "server" which is some tool built to understand a particular
-- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
-- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
-- processes that communicate with some "client" - in this case, Neovim!
--
-- LSP provides Neovim with features like:
--  - Go to definition
--  - Find references
--  - Autocompletion
--  - Symbol Search
--  - and more!
--
-- Thus, Language Servers are external tools that must be installed separately from
-- Neovim. This is where `mason` and related plugins come into play.
--
-- If you're wondering about lsp vs treesitter, you can check out the wonderfully
-- and elegantly composed help section, `:help lsp-vs-treesitter`

-- Useful status updates for LSP.
vim.pack.add({ "https://github.com/j-hui/fidget.nvim" })
require("fidget").setup({})

--- @param buf integer
--- @return vim.lsp.Client?
local function implementation_client(buf)
	local client = vim.iter(vim.lsp.get_clients({ bufnr = buf, method = "textDocument/typeDefinition" }))
		:find(function(c)
			return c:supports_method("textDocument/implementation", buf)
		end)

	if not client then
		vim.notify("No LSP client here answers both type definition and implementation", vim.log.levels.WARN)
	end

	return client
end

--- @param result lsp.Location|lsp.LocationLink|(lsp.Location|lsp.LocationLink)[]|nil
--- @return (lsp.Location|lsp.LocationLink)[]
local function as_list(result)
	if not result or vim.tbl_isempty(result) then
		return {}
	end

	return vim.islist(result) and result or { result }
end

local function loc_uri(loc)
	return loc.uri or loc.targetUri
end

local function loc_range(loc)
	return loc.range or loc.targetSelectionRange or loc.targetRange
end

local function loc_key(loc)
	local range = loc_range(loc)
	return ("%s:%d:%d"):format(loc_uri(loc), range.start.line, range.start.character)
end

local function show_locations(client, result, title)
	-- A picker built from a ready item list runs its finder synchronously, so a single
	-- auto-confirmed item closes the picker from inside snacks' own find(), which then
	-- touches the timer that close() just tore down. Jump such results ourselves.
	if #result == 1 then
		vim.lsp.util.show_document(result[1], client.offset_encoding, { reuse_win = true, focus = true })
		vim.cmd("normal! zz")
		return
	end

	local items = {}
	for _, loc in ipairs(vim.lsp.util.locations_to_items(result, client.offset_encoding)) do
		items[#items + 1] = {
			text = loc.filename .. " " .. loc.text,
			file = loc.filename,
			pos = { loc.lnum, loc.col - 1 },
			line = loc.text,
		}
	end

	require("snacks").picker.pick({
		source = "lsp_concrete_implementations",
		title = title,
		items = items,
		format = "file",
		jump = { tagstack = true, reuse_win = true },
	})
end

local function request_type_implementations(client, buf, params)
	client:request("textDocument/typeDefinition", params, function(err, result)
		-- A partial class declares itself in several places, so keep every location
		-- for the fallback and ask about the first one.
		local types = as_list(result)
		if err or #types == 0 then
			vim.notify("No type under the cursor", vim.log.levels.WARN)
			return
		end

		-- The type location came from this client, so its range is already in the
		-- client's offset encoding.
		client:request("textDocument/implementation", {
			textDocument = { uri = loc_uri(types[1]) },
			position = loc_range(types[1]).start,
		}, function(impl_err, impls)
			impls = as_list(impls)
			if impl_err or #impls == 0 then
				show_locations(client, types, "Type Definition")
				return
			end

			show_locations(client, impls, "Type Implementations")
		end, buf)
	end, buf)
end

local function goto_implementation_or_type()
	local buf = vim.api.nvim_get_current_buf()
	local win = vim.api.nvim_get_current_win()
	local client = implementation_client(buf)
	if not client then
		return
	end

	local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
	client:request("textDocument/implementation", params, function(err, result)
		local impls = as_list(result)
		if err or #impls == 0 then
			request_type_implementations(client, buf, params)
			return
		end

		-- A variable has no implementations of its own, so servers answer with its
		-- declaration. Those results carry no information that grd does not already
		-- give, so treat them as a miss and ask about the variable's type instead.
		client:request("textDocument/definition", params, function(_, definition)
			local defs = {}
			for _, loc in ipairs(as_list(definition)) do
				defs[loc_key(loc)] = true
			end

			impls = vim.tbl_filter(function(loc)
				return not defs[loc_key(loc)]
			end, impls)

			if #impls == 0 then
				request_type_implementations(client, buf, params)
				return
			end

			show_locations(client, impls, "Implementations")
		end, buf)
	end, buf)
end

--  This function gets run when an LSP attaches to a particular buffer.
--    That is to say, every time a new file is opened that is associated with
--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
--    function will be executed to configure the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
	callback = function(event)
		-- NOTE: Remember that Lua is a real programming language, and as such it is possible
		-- to define small helper and utility functions so you don't have to repeat yourself.
		--
		-- In this case, we create a function that lets us more easily define mappings specific
		-- for LSP related items. It sets the mode, buffer and description for us each time.
		local map = function(keys, func, desc, mode)
			mode = mode or "n"
			vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
		end

		-- Rename the variable under your cursor.
		--  Most Language Servers support renaming across files, etc.
		-- ts-autotag loads on a FileType trigger, so it is off the runtimepath in
		-- buffers whose filetype it does not handle.
		map("grn", function()
			local ok, autotag = pcall(require, "ts-autotag")
			if ok and autotag.rename() then
				return
			end

			require("live-rename").rename()
		end, "[R]e[n]ame")

		-- if not require("ts-autotag").rename() then
		-- 	require("live-rename").rename()
		-- end

		-- Execute a code action, usually your cursor needs to be on top of an error
		-- or a suggestion from your LSP for this to activate.
		map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })

		-- Find references for the word under your cursor.
		map("grr", function()
			require("snacks").picker.lsp_references()
		end, "[G]oto [R]eferences")

		-- Jump to the concrete code behind the word under your cursor: its
		--  implementations, else its type's implementations, else its type. Only a word
		--  with no type at all goes nowhere.
		map("gri", goto_implementation_or_type, "[G]oto [I]mplementation")

		-- Jump to the definition of the word under your cursor.
		--  This is where a variable was first declared, or where a function is defined, etc.
		--  To jump back, press <C-t>.
		map("grd", function()
			require("snacks").picker.lsp_definitions()
		end, "[G]oto [D]efinition")

		-- WARN: This is not Goto Definition, this is Goto Declaration.
		--  For example, in C this would take you to the header.
		map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

		-- Fuzzy find all the symbols in your current document.
		--  Symbols are things like variables, functions, types, etc.
		map("<leader>ssd", function()
			require("snacks").picker.lsp_symbols({
				filter = {
					default = true
				}
			})
		end, "[D]ocument")

		-- Fuzzy find all the symbols in your current workspace.
		--  Similar to document symbols, except searches over your entire project.
		map("<leader>ssw", function()
			require("snacks").picker.lsp_workspace_symbols()
		end, "[W]orkspace")

		-- Jump to the type of the word under your cursor.
		--  Useful when you're not sure what type a variable is and you want to see
		--  the definition of its *type*, not where it was *defined*.
		map("grtt", function()
			require("snacks").picker.lsp_type_definitions()
		end, "[G]oto [T]ype Definition")

		-- The following two autocommands are used to highlight references of the
		-- word under your cursor when your cursor rests there for a little while.
		--    See `:help CursorHold` for information about when this is executed
		--
		-- When you move your cursor, the highlights will be cleared (the second autocommand).
		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if client and client:supports_method("textDocument/documentHighlight", event.buf) then
			local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.document_highlight,
			})

			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.clear_references,
			})

			vim.api.nvim_create_autocmd("LspDetach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
				callback = function(event2)
					vim.lsp.buf.clear_references()
					vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
				end,
			})
		end

		-- The following code creates a keymap to toggle inlay hints in your
		-- code, if the language server you are using supports them
		--
		-- This may be unwanted, since they displace some of your code
		if client and client:supports_method("textDocument/inlayHint", event.buf) then
			map("<leader>th", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
			end, "[T]oggle Inlay [H]ints")
		end
	end,
})

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--  See `:help lsp-config` for information about keys and how to configure
---@type table<string, vim.lsp.Config>
local servers = {
	-- clangd = {},
	-- gopls = {},
	-- pyright = {},
	-- rust_analyzer = {},
	--
	-- Some languages (like typescript) have entire language plugins that can be useful:
	--    https://github.com/pmizio/typescript-tools.nvim
	--
	-- But for many setups, the LSP (`ts_ls`) will work just fine
	-- ts_ls = {},

	-- roslyn = {
	-- 	settings = {
	-- 		["csharp|code_lens"] = {
	-- 			dotnet_enable_references_code_lens = true,
	-- 		},
	-- 	},
	-- },

	stylua = {}, -- Used to format Lua code
	tombi = {},
	cssls = {},
	jsonls = {
		filetypes = { "json", "jsonc", "json5" },
	},
	emmet_language_server = {
		filetypes = { "html", "cshtml", "razor" },
	},
	html = {},
	htmx = {
		-- htmx-lsp advertises textDocument/hover but never replies to it, so any
		-- buf_request_all() hover in a buffer it attached to never completes.
		on_init = function(client)
			client.server_capabilities.hoverProvider = nil
		end,
	},
	rust_analyzer = {},
	bacon_ls = {},
	jinja_lsp = {},
	zls = {},

	-- Special Lua Config, as recommended by neovim help docs
	lua_ls = {
		on_init = function(client)
			client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

			if client.workspace_folders then
				local path = client.workspace_folders[1].name
				if
					path ~= vim.fn.stdpath("config")
					and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
				then
					return
				end
			end

			client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
				runtime = {
					version = "LuaJIT",
					path = { "lua/?.lua", "lua/?/init.lua" },
				},
				-- NOTE: workspace.library intentionally omitted. lazydev.nvim (see bottom of
				--  this file) loads lua_ls libraries on demand. Preloading the full runtime
				--  with nvim_get_runtime_file("", true) indexed 1700+ files and was slow.
				workspace = {
					checkThirdParty = false,
				},
			})
		end,
		---@type lspconfig.settings.lua_ls
		settings = {
			Lua = {
				format = { enable = false }, -- Disable formatting (formatting is done by stylua)
			},
		},
	},
}

vim.pack.add({
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/mason-org/mason-lspconfig.nvim",
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
})

-- Automatically install LSPs and related tools to stdpath for Neovim
require("mason").setup({
	registries = {
		"github:mason-org/mason-registry",
		"github:Crashdummyy/mason-registry",
	},
})

-- Ensure the servers and tools above are installed
--
-- To check the current status of installed tools and/or manually install
-- other tools, you can run
--    :Mason
--
-- You can press `g?` for help in this menu.
local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
	-- You can add other tools here that you want Mason to install
})

-- mason-tool-installer triggers its start-up check from a VimEnter autocmd it
-- registers in its own plugin/ file. This module is loaded through later(),
-- so VimEnter has already fired by then and that autocmd never runs, leaving
-- a fresh install with no tools. Run the check directly instead.
require("mason-tool-installer").setup({ ensure_installed = {}, run_on_start = false })
require("mason-tool-installer").check_install(false)

for name, server in pairs(servers) do
	vim.lsp.config(name, server)
	vim.lsp.enable(name)
end

-- vim.pack.add({ "https://github.com/mason-org/mason.nvim" })
-- require("mason").setup({
-- 	registries = {
-- 		"github:mason-org/mason-registry",
-- 		"github:Crashdummyy/mason-registry",
-- 	},
-- })
--
-- vim.pack.add({ "https://github.com/mason-org/mason-lspconfig.nvim" })
-- require("mason-lspconfig").setup({})
--
-- vim.pack.add({ "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" })
-- require("mason-tool-installer").setup({})
--
-- vim.pack.add({ "https://github.com/j-hui/fidget.nvim" })
-- require("fidget").setup({})

vim.pack.add({ "https://github.com/folke/lazydev.nvim" })
require("lazydev").setup({
	library = {
		{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
		{ path = "wezterm-types", mods = { "wezterm" } },
	},
})
