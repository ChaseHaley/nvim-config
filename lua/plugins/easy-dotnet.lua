require("plugins/dap")
-- NOTE: depends on:
-- nvim-lua/plenary.nvim
-- mfussenegger/nvim-dap
-- folke/snacks.nvim (optional)
vim.pack.add({ "https://github.com/GustavEikaas/easy-dotnet.nvim" })
require("easy-dotnet").setup(
	---@type easy-dotnet.Options
	{
		managed_terminal = {
			auto_hide = true, -- auto hides terminal if exit code is 0
			auto_hide_delay = 1000, -- delay before auto hiding, 0 = instant
			mappings = {
				next_tab = { lhs = "<Tab>", desc = "Next terminal tab" },
				prev_tab = { lhs = "<S-Tab>", desc = "Previous terminal tab" },
				new_terminal = { lhs = "+", desc = "New user terminal" },
				close_terminal = { lhs = "X", desc = "Close current terminal tab" },
				hide_panel = { lhs = "q", desc = "Hide terminal panel" },
			},
		},
		-- Optional configuration for external terminals (matches nvim-dap structure)
		external_terminal = vim.fn.has("win32") == 1
				and { command = "wt", args = { "-w", "0", "nt", "--" } }
			or { command = "xdg-terminal-exec", args = {} },
		projx_lsp = {
			enabled = true,
		},
		lsp = {
			enabled = true, -- Enable builtin roslyn lsp
			set_fold_expr = false,
			preload_roslyn = false, -- Start loading roslyn before any buffer is opened
			roslynator_enabled = false, -- Automatically enable roslynator analyzer
			easy_dotnet_analyzer_enabled = true, -- Enable roslyn analyzer from easy-dotnet-server
			easy_dotnet_extension_enabled = false, -- Needs to be true for enhanced_rename and create_type_from_usage
			enhanced_rename = false, -- auto rename file when renaming class
			create_type_from_usage = false, -- code action for creating class from unresolved symbol in a separate file
			restart_roslyn_on_branch_change = false, -- Restart Roslyn when Git HEAD changes
			auto_refresh_codelens = true,
			suggest_updates = true, -- Periodically suggest roslyn-language-server updates
			analyzer_assemblies = {}, -- Any additional roslyn analyzers you might use like SonarAnalyzer.CSharp
			auto_load_projects = true,
			razor = {
				enabled = true,
				html = {
					enabled = true,
					cmd = nil, -- Auto-detect project node_modules/.bin/vscode-html-language-server, then PATH
					request_timeout = 5000,
				},
			},
			config = {},
		},
		debugger = {
			-- Path to custom coreclr DAP adapter
			-- When set, this fully overrides `engine`; easy-dotnet-server uses this binary as-is.
			-- When nil, easy-dotnet-server falls back to its own bundled debugger selected by `engine`.
			bin_path = nil,
			-- Which bundled debugger to use when `bin_path` is nil.
			--   "netcoredbg" (default) — Samsung netcoredbg
			--   "dncdbg"               — viewizard/dncdbg (a fork of netcoredbg with a richer set of features)
			engine = "netcoredbg",
			console = "externalTerminal", -- Controls where the target app runs: "integratedTerminal" (Neovim buffer) or "externalTerminal" (OS window)
			apply_value_converters = true,
			auto_register_dap = true,
			mappings = {
				open_variable_viewer = { lhs = "T", desc = "open variable viewer" },
			},
		},
		---@type easy-dotnet.TestRunner.Options
		test_runner = {
			auto_start_testrunner = true,
			hide_legend = false,
			-- Set to true when using neotest to avoid duplicate signs and conflicting buffer keymaps.
			neotest_integration = false,
			---@type "split" | "vsplit" | "float" | "buf"
			viewmode = "float",
			---@type number|nil
			vsplit_width = nil,
			---@type string|nil "topleft" | "topright"
			vsplit_pos = nil,
			icons = {
				passed = "",
				skipped = "",
				failed = "",
				success = "",
				reload = "",
				test = "",
				sln = "󰘐",
				project = "󰘐",
				dir = "",
				package = "",
				class = "",
				build_failed = "󰒡",
			},
			mappings = {
				run_test_from_buffer = { lhs = "<leader>r", desc = "run test from buffer" },
				run_all_tests_from_buffer = { lhs = "<leader>t", desc = "Run all tests in file" },
				get_build_errors = { lhs = "<leader>e", desc = "get build errors" },
				peek_stack_trace_from_buffer = { lhs = "<leader>p", desc = "peek stack trace from buffer" },
				debug_test_from_buffer = { lhs = "<leader>d", desc = "run test from buffer" },
				debug_test = { lhs = "<leader>d", desc = "debug test" },
				go_to_file = { lhs = "<leader>g", desc = "go to file" },
				run_all = { lhs = "<leader>R", desc = "run all tests" },
				run = { lhs = "<leader>r", desc = "run test" },
				peek_stacktrace = { lhs = "<leader>p", desc = "peek stacktrace of failed test" },
				expand = { lhs = "o", desc = "expand" },
				expand_node = { lhs = "E", desc = "expand node" },
				collapse_all = { lhs = "W", desc = "collapse all" },
				close = { lhs = "q", desc = "close testrunner" },
				refresh_testrunner = { lhs = "<C-r>", desc = "refresh testrunner" },
				cancel = { lhs = "<C-c>", desc = "cancel in-flight operation" },
			},
		},
		new = {
			project = {
				prefix = "sln", -- "sln" | "none"
			},
		},
		csproj_mappings = true,
		fsproj_mappings = true,
		auto_bootstrap_namespace = {
			--block_scoped, file_scoped
			type = "block_scoped",
			enabled = true,
			use_clipboard_json = {
				behavior = "prompt", --'auto' | 'prompt' | 'never',
				register = "+", -- which register to check
			},
		},
		server = {
			use_visual_studio = true, -- Set true for .NET Framework support on Windows
			---@type nil | "Off" | "Critical" | "Error" | "Warning" | "Information" | "Verbose" | "All"
			log_level = nil,
		},
		-- choose which picker to use with the plugin
		-- possible values are "telescope" | "fzf" | "snacks" | "basic"
		-- if no picker is specified, the plugin will determine
		-- the available one automatically with this priority:
		--  snacks -> fzf -> telescope ->  basic
		picker = "snacks",
		notifications = {
			--Set this to false if you have configured lualine to avoid double logging
			handler = function(start_event)
				local spinner = require("easy-dotnet.ui-modules.spinner").new()
				spinner:start_spinner(function()
					return start_event.job.name
				end)
				---@param finished_event JobEvent
				return function(finished_event)
					spinner:stop_spinner(finished_event.result.msg, finished_event.result.level)
				end
			end,
		},
		diagnostics = {
			default_severity = "error",
			setqflist = false,
		},
		outdated = {
			mappings = {
				upgrade = { lhs = "<leader>pu", desc = "upgrade package under cursor" },
				upgrade_all = { lhs = "<leader>pa", desc = "upgrade all outdated packages" },
			},
		},
	}
)

require("dap").configurations.razor = require("dap").configurations.cs
require("dap").configurations.css = require("dap").configurations.cs
require("dap").configurations.js = require("dap").configurations.cs
