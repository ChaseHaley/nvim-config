return {
	'folke/snacks.nvim',
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
		bigfile = { enabled = true },
		dashboard = { enabled = false },
		explorer = { enabled = false },
		indent = { enabled = false },
		input = { enabled = false },
		lazygit = { enabled = false },
		notifier = { enabled = false },
		picker = {
			enabled = true,
			layout = {
				preset = 'default'
			},
		},
		quickfile = { enabled = false },
		scope = { enabled = false },
		scroll = { enabled = false },
		statuscolumn = { enabled = false },
		words = { enabled = false },
	},
	config = function(_, opts)
		require('snacks').setup(opts)

		-- MonkeyPatch - https://github.com/folke/snacks.nvim/pull/2012
		local M = require 'snacks.picker.core.main'
		M.new = function(opts)
			opts = vim.tbl_extend('force', {
				float = false,
				file = true,
				current = false,
			}, opts or {})
			local self = setmetatable({}, M)
			self.opts = opts
			self.win = vim.api.nvim_get_current_win()
			return self
		end
	end,
	keys = {
		-- Search keymaps (replacing Telescope)
		{
			'<leader>sh',
			function()
				require('snacks').picker.help()
			end,
			desc = '[S]earch [H]elp',
		},
		{
			'<leader>sk',
			function()
				require('snacks').picker.keymaps()
			end,
			desc = '[S]earch [K]eymaps',
		},
		{
			'<leader>sf',
			function()
				require('snacks').picker.smart()
			end,
			desc = '[S]earch [F]iles',
		},
		{
			'<leader>sif',
			function()
				require('snacks').picker.files { hidden = true, no_ignore = true }
			end,
			desc = '[S]earch [I]gnored [F]iles',
		},
		{
			'<leader>sp',
			function()
				require('snacks').picker.pickers()
			end,
			desc = '[S]earch [P]ickers',
		},
		{
			'<leader>su',
			function()
				require('snacks').picker.undo()
			end,
			desc = '[S]earch [U]ndo',
		},
		{
			'<leader>sw',
			function()
				require('snacks').picker.grep_word()
			end,
			desc = '[S]earch current [W]ord',
			mode = { 'n', 'x' },
		},
		{
			'<leader>sg',
			function()
				require('snacks').picker.grep()
			end,
			desc = '[S]earch by [G]rep',
		},
		{
			'<leader>sde',
			function()
				require('snacks').picker.diagnostics { severity = vim.diagnostic.severity.ERROR }
			end,
			desc = '[S]earch [D]iagnostic [E]rrors',
		},
		{
			'<leader>sdw',
			function()
				require('snacks').picker.diagnostics { severity = vim.diagnostic.severity.WARN }
			end,
			desc = '[S]earch [D]iagnostic [W]arnings',
		},
		{
			'<leader>sdd',
			function()
				require('snacks').picker.diagnostics()
			end,
			desc = '[S]earch [DD]iagnostic All',
		},
		{
			'<leader>sr',
			function()
				require('snacks').picker.resume()
			end,
			desc = '[S]earch [R]esume',
		},
		{
			'<leader>s.',
			function()
				require('snacks').picker.recent()
			end,
			desc = '[S]earch Recent Files ("." for repeat)',
		},
		{
			'<leader><leader>',
			function()
				require('snacks').picker.buffers()
			end,
			desc = '[ ] Find existing buffers',
		},
		{
			'<leader>sm',
			function()
				require('snacks').picker.marks()
			end,
			desc = '[S]earch [M]arks',
		},
		{
			'<leader>/',
			function()
				require('snacks').picker.lines()
			end,
			desc = '[/] Fuzzily search in current buffer',
		},
		{
			'<leader>s/',
			function()
				require('snacks').picker.grep_buffers()
			end,
			desc = '[S]earch [/] in Open Files',
		},
		{
			'<leader>sn',
			function()
				require('snacks').picker.files { cwd = vim.fn.stdpath 'config' }
			end,
			desc = '[S]earch [N]eovim files',
		},
		{
			'<leader>sx',
			function()
				require('snacks').picker.git_status()
			end,
			desc = 'Search git status',
		},
		{
			'<leader>s;',
			function()
				require('snacks').picker.spelling()
			end,
			desc = 'Search git status',
		},
	},
}
