if vim.g.vscode then
	return {}
end

return {
	{
		'zbirenbaum/copilot.lua',
		dependencies = {
			'copilotlsp-nvim/copilot-lsp',
			init = function ()
				vim.g.copilot_nes_debounce = 500
			end,
		},
		cmd = 'Copilot',
		event = 'InsertEnter',
		--- @module 'copilot'
		--- @type CopilotConfig
		opts = {
			panel = {
				enabled = true,
				auto_refresh = false,
				keymap = {
					jump_prev = '[[',
					jump_next = ']]',
					accept = '<CR>',
					refresh = 'gr',
					open = '<M-CR>',
				},
				layout = {
					position = 'bottom', -- | top | left | right | bottom |
					ratio = 0.4,
				},
			},
			suggestion = {
				enabled = true,
				auto_trigger = true,
				trigger_on_accept = true,
				hide_during_completion = true,
				debounce = 75,
				keymap = {
					accept = '<M-l>',
					accept_word = '<M-j>',
					accept_line = '<M-k>',
					next = '<M-]>',
					prev = '<M-[>',
					dismiss = '<M-h>',
				},
			},
			nes = {
				enabled = true,
				keymap = {
					accept_and_goto = "<leader>l",
					accept = false,
					dismiss = "<Esc>",
				}
			},
			filetypes = {
				['*'] = false,
				typescript = true,
				cs = true,
				xml = true,
				csv = true,
			},
			auth_provider_url = nil, -- URL to authentication provider, if not "https://github.com/"
			logger = {
				file = vim.fn.stdpath 'log' .. '/copilot-lua.log',
				file_log_level = vim.log.levels.OFF,
				print_log_level = vim.log.levels.WARN,
				trace_lsp = 'off', -- "off" | "messages" | "verbose"
				trace_lsp_progress = false,
				log_lsp_messages = false,
			},
			copilot_node_command = 'node', -- Node.js version must be > 20
			workspace_folders = {},
			copilot_model = '',
			root_dir = function()
				return vim.fs.dirname(vim.fs.find('.git', { upward = true })[1])
			end,
			should_attach = function(_, _)
				if not vim.bo.buflisted then
					return false
				end

				if vim.bo.buftype ~= '' then
					return false
				end

				return true
			end,
			server = {
				type = 'nodejs', -- "nodejs" | "binary"
				custom_server_filepath = nil,
			},
			server_opts_overrides = {},
		},
	},
	-- {
	-- 	'giuxtaposition/blink-cmp-copilot',
	-- },
}
