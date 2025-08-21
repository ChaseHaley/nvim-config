if Is_Windows() or vim.g.vscode then
	return {}
end

return {
	'alexghergh/nvim-tmux-navigation',
	opts = {
		keybindings = {
			left = '<C-h>',
			down = '<C-j>',
			up = '<C-k>',
			right = '<C-l>',
			last_active = '<C-\\>',
			next = '<C-Space>',
		},
	},
}
