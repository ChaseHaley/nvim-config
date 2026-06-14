-- NOTE: You can also specify plugin using a version range for its git tag.
--  See `:help vim.version.range()` for more info
vim.pack.add({ { src = "https://github.com/L3MON4D3/LuaSnip", version = vim.version.range("2.*") } })
require("luasnip").setup({})

-- `friendly-snippets` contains a variety of premade snippets.
--    See the README about individual language/framework/plugin snippets:
--    https://github.com/rafamadriz/friendly-snippets
--
vim.pack.add({ "https://github.com/rafamadriz/friendly-snippets" })
require("luasnip.loaders.from_vscode").lazy_load()

-- [[ Autocomplete Engine ]]
vim.pack.add({ { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") } })

--- @module "blink.cmp"
--- @type blink.cmp.Config
local opts = {
	keymap = {
		-- 'default' (recommended) for mappings similar to built-in completions
		--   <c-y> to accept ([y]es) the completion.
		--    This will auto-import if your LSP supports it.
		--    This will expand snippets if the LSP sent a snippet.
		-- 'super-tab' for tab to accept
		-- 'enter' for enter to accept
		-- 'none' for no mappings
		--
		-- For an understanding of why the 'default' preset is recommended,
		-- you will need to read `:help ins-completion`
		--
		-- No, but seriously. Please read `:help ins-completion`, it is really good!
		--
		-- All presets have the following mappings:
		-- <tab>/<s-tab>: move to right/left of your snippet expansion
		-- <c-space>: Open menu or open docs if already open
		-- <c-n>/<c-p> or <up>/<down>: Select next/previous item
		-- <c-e>: Hide menu
		-- <c-k>: Toggle signature help
		--
		-- See `:help blink-cmp-config-keymap` for defining your own keymap
		-- preset = "default",

		-- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
		--    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
		["<C-w>"] = { "show", "show_documentation", "hide_documentation", "fallback" },
		["<C-e>"] = { "hide", "fallback" },
		["<C-y>"] = { "select_and_accept", "fallback" },

		["<Up>"] = { "select_prev", "fallback" },
		["<Down>"] = { "select_next", "fallback" },
		["<C-p>"] = { "select_prev", "fallback_to_mappings" },
		["<C-n>"] = { "select_next", "fallback_to_mappings" },

		["<C-b>"] = { "scroll_documentation_up", "fallback" },
		["<C-f>"] = { "scroll_documentation_down", "fallback" },

		["<Tab>"] = { "snippet_forward", "fallback" },
		["<S-Tab>"] = { "snippet_backward", "fallback" },

		["<C-k>"] = { "show_signature", "hide_signature", "fallback" },

		["<C-u>"] = { "scroll_signature_up", "fallback" },
		["<C-d>"] = { "scroll_signature_down", "fallback" },

		-- Fixes unexpected behavior of menu opening on <cr>
		["<cr>"] = { "fallback" }
	},

	appearance = {
		-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
		-- Adjusts spacing to ensure icons are aligned
		nerd_font_variant = "mono",
	},

	completion = {
		keyword = { range = "full" },
		-- By default, you may press `<c-space>` to show the documentation.
		-- Optionally, set `auto_show = true` to show the documentation after a delay.
		documentation = {
			-- Controls whether the documentation window will automatically show when selecting a completion item
			auto_show = true,

			-- Delay before showing the documentation window
			auto_show_delay_ms = 500,
			-- Delay before updating the documentation window when selecting a new item,
			-- while an existing item is still visible
			update_delay_ms = 50,
			-- Whether to use treesitter highlighting, disable if you run into performance issues
			treesitter_highlighting = true,
			-- Draws the item in the documentation window, by default using an internal treesitter based implementation
			draw = function(opts)
				opts.default_implementation()
			end,
			window = {
				min_width = 10,
				max_width = 80,
				max_height = 20,
				border = nil, -- Defaults to `vim.o.winborder` on nvim 0.11+ or 'padded' when not defined/<=0.10
				winblend = 0,
				winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
				-- Note that the gutter will be disabled when border ~= 'none'
				scrollbar = true,
				-- Which directions to show the documentation window,
				-- for each of the possible menu window directions,
				-- falling back to the next direction when there's not enough space
				direction_priority = {
					menu_north = { "e", "w", "n", "s" },
					menu_south = { "e", "w", "s", "n" },
				},
			},
		},

		-- https://cmp.saghen.dev/configuration/reference#completion-trigger
		trigger = {
			-- When true, will prefetch the completion items when entering insert mode
			prefetch_on_insert = true,

			-- When false, will not show the completion window automatically when in a snippet
			show_in_snippet = true,

			-- When true, will show completion window after backspacing
			show_on_backspace = true,

			-- When true, will show completion window after backspacing into a keyword
			show_on_backspace_in_keyword = true,

			-- When true, will show the completion window after accepting a completion and then backspacing into a keyword
			show_on_backspace_after_accept = true,

			-- When true, will show the completion window after entering insert mode and backspacing into keyword
			show_on_backspace_after_insert_enter = true,

			-- When true, will show the completion window after typing any of alphanumerics, `-` or `_`
			show_on_keyword = true,

			-- When true, will show the completion window after typing a trigger character
			show_on_trigger_character = true,

			-- When true, will show the completion window after entering insert mode
			show_on_insert = true,

			-- LSPs can indicate when to show the completion window via trigger characters
			-- however, some LSPs (e.g. tsserver) return characters that would essentially
			-- always show the window. We block these by default.
			show_on_blocked_trigger_characters = { " ", "\n", "\t" },
			-- You can also block per filetype with a function:
			-- show_on_blocked_trigger_characters = function(ctx)
			--   if vim.bo.filetype == 'markdown' then return { ' ', '\n', '\t', '.', '/', '(', '[' } end
			--   return { ' ', '\n', '\t' }
			-- end,

			-- When both this and show_on_trigger_character are true, will show the completion window
			-- when the cursor comes after a trigger character after accepting an item
			show_on_accept_on_trigger_character = true,

			-- When both this and show_on_trigger_character are true, will show the completion window
			-- when the cursor comes after a trigger character when entering insert mode
			show_on_insert_on_trigger_character = true,

			-- List of trigger characters (on top of `show_on_blocked_trigger_characters`) that won't trigger
			-- the completion window when the cursor comes after a trigger character when
			-- entering insert mode/accepting an item
			show_on_x_blocked_trigger_characters = { "'", '"', "(" },
			-- or a function, similar to show_on_blocked_trigger_character
		},

		list = {
			-- Maximum number of items to display
			max_items = 200,

			selection = {
				-- When `true`, will automatically select the first item in the completion list
				preselect = true,
				-- preselect = function(ctx) return vim.bo.filetype ~= 'markdown' end,

				-- When `true`, inserts the completion item automatically when selecting it
				-- You may want to bind a key to the `cancel` command (default <C-e>) when using this option,
				-- which will both undo the selection and hide the completion menu
				auto_insert = false,
				-- auto_insert = function(ctx) return vim.bo.filetype ~= 'markdown' end
			},

			cycle = {
				-- When `true`, calling `select_next` at the _bottom_ of the completion list
				-- will select the _first_ completion item.
				from_bottom = true,
				-- When `true`, calling `select_prev` at the _top_ of the completion list
				-- will select the _last_ completion item.
				from_top = true,
			},
		},

		menu = {
			enabled = true,
			min_width = 15,
			max_height = 10,
			border = nil, -- Defaults to `vim.o.winborder` on nvim 0.11+
			winblend = 0,
			winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
			-- Keep the cursor X lines away from the top/bottom of the window
			scrolloff = 2,
			-- Note that the gutter will be disabled when border ~= 'none'
			scrollbar = true,
			-- Which directions to show the window,
			-- falling back to the next direction when there's not enough space
			direction_priority = { "s", "n" },
			-- Can accept a function if you need more control
			-- direction_priority = function()
			--   if condition then return { 'n', 's' } end
			--   return { 's', 'n' }
			-- end,

			-- Whether to automatically show the window when new completion items are available
			auto_show = true,
			-- Delay before showing the completion menu
			auto_show_delay_ms = 0,

			-- Screen coordinates of the command line
			cmdline_position = function()
				if vim.g.ui_cmdline_pos ~= nil then
					local pos = vim.g.ui_cmdline_pos -- (1, 0)-indexed
					return { pos[1] - 1, pos[2] }
				end
				local height = (vim.o.cmdheight == 0) and 1 or vim.o.cmdheight
				return { vim.o.lines - height, 0 }
			end,
		},

		ghost_text = {
			enabled = true,
			-- Show the ghost text when an item has been selected
			show_with_selection = true,
			-- Show the ghost text when no item has been selected, defaulting to the first item
			show_without_selection = false,
			-- Show the ghost text when the menu is open
			show_with_menu = true,
			-- Show the ghost text when the menu is closed
			show_without_menu = true,
		},
	},

	sources = {
		default = { "lsp", "path", "snippets" },
	},

	snippets = { preset = "luasnip" },

	-- Blink.cmp includes an optional, recommended rust fuzzy matcher,
	-- which automatically downloads a prebuilt binary when enabled.
	--
	-- By default, we use the Lua implementation instead, but you may enable
	-- the rust implementation via `'prefer_rust_with_warning'`
	--
	-- See `:help blink-cmp-config-fuzzy` for more information
	fuzzy = { implementation = "lua" },

	-- Shows a signature help window while you type arguments for a function
	signature = {
		enabled = true,
		trigger = {
			-- Show the signature help automatically
			enabled = true,
			-- Show the signature help window after typing any of alphanumerics, `-` or `_`
			show_on_keyword = true,
			blocked_trigger_characters = {},
			blocked_retrigger_characters = {},
			-- Show the signature help window after typing a trigger character
			show_on_trigger_character = true,
			-- Show the signature help window when entering insert mode
			show_on_insert = true,
			-- Show the signature help window when the cursor comes after a trigger character when entering insert mode
			show_on_insert_on_trigger_character = true,
		},
		window = {
			min_width = 1,
			max_width = 100,
			max_height = 10,
			border = nil, -- Defaults to `vim.o.winborder` on nvim 0.11+ or 'padded' when not defined/<=0.10
			winblend = 0,
			winhighlight = "Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder",
			scrollbar = true, -- Note that the gutter will be disabled when border ~= 'none'
			-- Which directions to show the window,
			-- falling back to the next direction when there's not enough space,
			-- or another window is in the way
			direction_priority = { "n", "s" },
			-- Can accept a function if you need more control
			-- direction_priority = function()
			--   if condition then return { 'n', 's' } end
			--   return { 's', 'n' }
			-- end,

			-- Disable if you run into performance issues
			treesitter_highlighting = true,
			show_documentation = true,
		},
	},
}
require("blink.cmp").setup(opts)

vim.pack.add({ "https://github.com/saecki/live-rename.nvim" })
require("live-rename").setup({})
