if vim.uv.os_uname().sysname == 'Windows_NT' or vim.g.vscode then
	return {}
end

return {
	'mbbill/undotree',
}
