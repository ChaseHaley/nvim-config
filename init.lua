vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.have_nerd_font = true

require("utilities")
require("options")
require("keymaps")
require("commands")
require("autocommands")
require("pack_inspect").setup()
if #vim.api.nvim_get_runtime_file("lua/local.lua", false) > 0 then
	require("local")
end
require("plugins")
