vim.pack.add({ "https://github.com/sindrets/diffview.nvim" })
require("diffview").setup({})

vim.keymap.set("n", "<leader>gdf", "<cmd>DiffviewFileHistory --follow %<CR>")
vim.keymap.set("n", "<leader>gda", "<cmd>DiffviewOpen<CR>")
