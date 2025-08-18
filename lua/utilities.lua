function Is_Windows()
	return vim.uv.os_uname().sysname == 'Windows_NT'
end
