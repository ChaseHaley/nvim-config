return {
	'epwalsh/obsidian.nvim',
	version = '*', -- recommended, use latest release instead of latest commit
	event = "VeryLazy",
	ft = 'markdown',
	-- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
	-- event = {
	--   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
	--   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
	--   -- refer to `:h file-pattern` for more examples
	--   "BufReadPre path/to/my-vault/*.md",
	--   "BufNewFile path/to/my-vault/*.md",
	-- },
	dependencies = {
		-- Required.
		'nvim-lua/plenary.nvim',

		-- see below for full list of optional dependencies 👇
		'saghen/blink.cmp',
		'nvim-telescope/telescope.nvim',
	},
	opts = {},
	config = function()
		local main_vault_name = '~/Main/Obsidian Vaults/Git Lite'
		if Is_Windows() then
			main_vault_name = 'C:/Dev/Extras/Obsidian/Main Vault/'
		end
		require('obsidian').setup {
			ui = { enabled = false }, -- use render-markdown instead
			workspaces = {
				{
					name = 'main',
					path = main_vault_name,
					strict = true
				},
			},
			completion = {
				nvim_cmp = false,
				blink = true,
			},
			disable_frontmatter = true,
			picker = {
				name = 'telescope.nvim',
			},
		}
	end,
}
