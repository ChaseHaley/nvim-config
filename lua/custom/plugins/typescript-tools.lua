if vim.g.vscode then
	return {}
end

return {
	'pmizio/typescript-tools.nvim',
	dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
	opts = {},
}
