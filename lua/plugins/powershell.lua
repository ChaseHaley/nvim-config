vim.pack.add({ "https://github.com/TheLeoP/powershell.nvim" })
---@type powershell.user_config
require("powershell").setup({
	bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
})
