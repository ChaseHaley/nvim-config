if vim.g.vscode then
	return {}
end

-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
	'nvim-neo-tree/neo-tree.nvim',
	version = '*',
	dependencies = {
		'nvim-lua/plenary.nvim',
		'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
		'MunifTanjim/nui.nvim',
	},
	lazy = false,
	keys = {
		{ '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
	},
	opts = {
		filesystem = {
			window = {
				mappings = {
					['\\'] = 'close_window',
				},
			},
		},
	},
	-- config = function()
	-- 	if not Is_Windows() then
	-- 		local events = require 'neo-tree.events'
	-- 		require('neo-tree').setup {
	-- 			event_handlers = {
	-- 				{
	-- 					event = events.NEO_TREE_BUFFER_ENTER,
	-- 					handler = function()
	-- 						vim.opt_local.cursorline = false
	-- 						vim.wo.winhighlight = 'CursorLine:Normal,CursorLineNr:LineNr'
	-- 					end,
	-- 				},
	-- 			},
	-- 			filesystem = {
	-- 				window = {
	-- 					mappings = {
	-- 						['\\'] = 'close_window',
	-- 					},
	-- 				},
	-- 			},
	-- 		}
	-- 	end
	-- end,
}
