if Is_Windows() then
	return {
		'Kurren123/mssql.nvim',
		opts = {
			keymap_prefix = '<leader>m',
		},
	}
else
	return {}
end
