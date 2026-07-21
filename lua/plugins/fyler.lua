vim.pack.add({ "https://github.com/FylerOrg/fyler.nvim" })

---@type fyler.UserConfig
require('fyler').setup({
	integrations = {
		-- icon = 'nvim_web_devicons'
		icon = 'mini_icons'
	},
	ui = {
		indent_guides = true
	},
	kind_presets = {
		split_left_most = { width = "15%" }
	}
})

local fyler = require('fyler')
vim.keymap.set('n', '<leader>st', function ()
	fyler.open({ kind = "split_left_most" })
end, { desc = "[Search] File [T]ree" })

vim.keymap.set('n', '<leader>tt', function ()
	fyler.toggle({ kind = "split_left_most" })
end, { desc = "[T]oggle File [T]ree"})
