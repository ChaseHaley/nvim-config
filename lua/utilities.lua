-- Creates an encoded URI key for a directory
function Key_for(dir)
	return vim.uri_encode(vim.fs.normalize(dir), 'rfc2396')
end
