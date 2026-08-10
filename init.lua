vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.have_nerd_font = true

require("utilities")
require("options")
require("keymaps")
require("commands")
require("autocommands")
require("pack_inspect").setup()
require("plugins")
