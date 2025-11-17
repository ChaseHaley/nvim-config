if vim.g.vscode then
	return {}
end

-- NOTE: Plugins can specify dependencies.
--
-- The dependencies are proper plugin specifications as well - anything
-- you do for a plugin at the top level, you can do for a dependency.
--
-- Use the `dependencies` key to specify the dependencies of a particular plugin

return {
	{ -- Fuzzy Finder (files, lsp, etc)
		'nvim-telescope/telescope.nvim',
		event = 'VimEnter',
		dependencies = {
			'nvim-lua/plenary.nvim',
			{ -- If encountering errors, see telescope-fzf-native README for installation instructions
				'nvim-telescope/telescope-fzf-native.nvim',

				-- `build` is used to run some command when the plugin is installed/updated.
				-- This is only run then, not every time Neovim starts up.
				build = 'make',

				-- `cond` is a condition used to determine whether this plugin should be
				-- installed and loaded.
				cond = function()
					return vim.fn.executable 'make' == 1
				end,
			},
			{ 'nvim-telescope/telescope-ui-select.nvim' },
			{ 'debugloop/telescope-undo.nvim' },

			-- Useful for getting pretty icons, but requires a Nerd Font.
			{ 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },

			{
				'nvim-telescope/telescope-live-grep-args.nvim',
				-- This will not install any breaking changes.
				-- For major updates, this must be adjusted manually.
				version = '^1.0.0',
			},
		},
		config = function()
			-- Telescope is a fuzzy finder that comes with a lot of different things that
			-- it can fuzzy find! It's more than just a "file finder", it can search
			-- many different aspects of Neovim, your workspace, LSP, and more!
			--
			-- The easiest way to use Telescope, is to start by doing something like:
			--  :Telescope help_tags
			--
			-- After running this command, a window will open up and you're able to
			-- type in the prompt window. You'll see a list of `help_tags` options and
			-- a corresponding preview of the help.
			--
			-- Two important keymaps to use while in Telescope are:
			--  - Insert mode: <c-/>
			--  - Normal mode: ?
			--
			-- This opens a window that shows you all of the keymaps for the current
			-- Telescope picker. This is really useful to discover what Telescope can
			-- do as well as how to actually do it!

			-- https://github.com/nvim-telescope/telescope-live-grep-args.nvim
			local lga_actions = require 'telescope-live-grep-args.actions'

			-- [[ Configure Telescope ]]
			-- See `:help telescope` and `:help telescope.setup()`
			require('telescope').setup {
				-- You can put your default mappings / updates / etc. in here
				--  All the info you're looking for is in `:help telescope.setup()`
				--
				-- defaults = {
				--   mappings = {
				--     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
				--   },
				-- },
				pickers = {
					find_files = {
						hidden = true,
					},
				},
				defaults = {
					file_ignore_patterns = {
						'%__virtual.cs$',
						'%cshtml__virtual.html$',
					},
				},
				extensions = {
					['ui-select'] = {
						require('telescope.themes').get_dropdown(),
					},
					undo = {
						side_by_side = true,
						layout_strategy = 'horizontal',
						layout_config = {
							preview_width = 0.8,
						},
						mappings = {
							i = {
								['<CR>'] = require('telescope-undo.actions').restore,
								['<C-y>'] = require('telescope-undo.actions').yank_additions,
								['<C-d>'] = require('telescope-undo.actions').yank_deletions,

								-- https://github.com/nvim-telescope/telescope-live-grep-args.nvim
								['<C-k>'] = lga_actions.quote_prompt(),
								['<C-i>'] = lga_actions.quote_prompt { postfix = ' --iglob ' },
								['<C-space>'] = lga_actions.to_fuzzy_refine, -- freeze the current list and start a fuzzy search in the frozen list
							},
							n = {
								['<CR>'] = require('telescope-undo.actions').restore,
								['<C-c>'] = require('telescope-undo.actions').yank_additions,
								['<C-d>'] = require('telescope-undo.actions').yank_deletions,
							},
						},
					},
				},
			}

			-- Enable Telescope extensions if they are installed
			pcall(require('telescope').load_extension, 'fzf')
			pcall(require('telescope').load_extension, 'ui-select')
			pcall(require('telescope').load_extension, 'live_grep_args')

			-- See `:help telescope.builtin`
			local builtin = require 'telescope.builtin'
			vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
			vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
			vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
			vim.keymap.set('n', '<leader>sif', function()
				builtin.find_files { no_ignore = true }
			end, { desc = '[S]earch [I]gnored [F]iles' })
			vim.keymap.set('n', '<leader>st', builtin.builtin, { desc = '[S]earch [T]elescope' })
			vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
			-- vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
			vim.keymap.set('n', '<leader>sg', ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", { desc = '[S]earch by [G]rep' })
			vim.keymap.set('n', '<leader>sde', function ()
        builtin.diagnostics({ severity_limit = 'ERROR' })
			end, { desc = '[S]earch [D]iagnostic [E]rrors' })
			vim.keymap.set('n', '<leader>sdw', function ()
        builtin.diagnostics({ severity_limit = 'WARN' })
			end, { desc = '[S]earch [D]iagnostic [W]arnings+' })
			vim.keymap.set('n', '<leader>sdd', builtin.diagnostics, { desc = '[S]earch [DD]iagnostic All' })
			vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
			vim.keymap.set('n', '<leader>s;', builtin.spell_suggest, { desc = '[S]earch Spell Suggestions' })
			vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
			-- vim.keymap.set('n', '<leader>u', function()
			-- 	vim.cmd 'Telescope undo'
			-- end, { desc = '[U]ndo History' })
			vim.keymap.set('n', '<leader>sm', builtin.marks, { desc = '[S]earch [M]arks' })
			-- Slightly advanced example of overriding default behavior and theme
			vim.keymap.set('n', '<leader>/', function()
				-- You can pass additional configuration to Telescope to change the theme, layout, etc.
				builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
					winblend = 10,
					previewer = false,
				})
			end, { desc = '[/] Fuzzily search in current buffer' })

			-- It's also possible to pass additional configuration options.
			--  See `:help telescope.builtin.live_grep()` for information about particular keys
			vim.keymap.set('n', '<leader>s/', function()
				builtin.live_grep {
					grep_open_files = true,
					prompt_title = 'Live Grep in Open Files',
				}
			end, { desc = '[S]earch [/] in Open Files' })

			-- Shortcut for searching your Neovim configuration files
			vim.keymap.set('n', '<leader>sn', function()
				builtin.find_files { cwd = vim.fn.stdpath 'config' }
			end, { desc = '[S]earch [N]eovim files' })

			vim.keymap.set('n', '<leader>sx', builtin.git_status, { desc = 'Search git status' })
			vim.keymap.set('n', '<leader>so', '<Cmd>ObsidianQuickSwitch<CR>', { desc = '[S]earch [O]bsidian notes' })
		end,
	},
}
-- vim: ts=2 sts=2 sw=2 et
