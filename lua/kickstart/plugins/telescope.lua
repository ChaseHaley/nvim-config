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
	{ -- Fuzzy Finder (files, lsp, etc) - MOSTLY REPLACED WITH SNACKS.PICKER
		-- NOTE: Telescope is kept installed but disabled for primary use.
		-- It's only loaded as a dependency where needed to fill gaps in Snacks.picker functionality.
		-- Example: Harpoon list management (reordering, deleting entries with custom keymaps)
		-- 
		-- Primary picker: Snacks.picker (see lua/custom/plugins/snacks.lua)
		-- Gap-filling: Telescope (loaded on-demand by specific plugins like Harpoon)
		'nvim-telescope/telescope.nvim',
		enabled = true, -- Enabled for gap-filling purposes only
		lazy = true, -- Only load when required by other plugins
		event = 'VeryLazy',
		dependencies = {
			'nvim-lua/plenary.nvim',
			-- Useful for getting pretty icons, but requires a Nerd Font.
			{ 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
		},
		config = function()
			-- Minimal Telescope configuration for gap-filling use cases
			-- This is NOT the primary picker - see Snacks.picker in lua/custom/plugins/snacks.lua
			require('telescope').setup {
				defaults = {
					file_ignore_patterns = {
						'%__virtual.cs$',
						'%cshtml__virtual.html$',
					},
				},
			}
		end,
	},
}
-- vim: ts=2 sts=2 sw=2 et
