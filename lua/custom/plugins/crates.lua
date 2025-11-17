if Is_Windows() or vim.g.vscode then
	return {}
end

return {
	'saecki/crates.nvim',
	tag = 'stable',
	config = function()
		require('crates').setup()
	end,
}
