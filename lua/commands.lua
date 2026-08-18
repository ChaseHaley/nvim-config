vim.api.nvim_create_user_command("CheckKey", "echo keytrans(getcharstr())", {})
vim.api.nvim_create_user_command("W", "w", {})

vim.api.nvim_create_user_command("DiffScratch", function(opts)
	local ft = opts.args
	vim.cmd("tabnew")
	local function scratch()
		vim.bo.buftype, vim.bo.bufhidden, vim.bo.swapfile = "nofile", "wipe", false
		if ft ~= "" then
			vim.bo.filetype = ft
		end
		vim.cmd("diffthis")
	end
	scratch()
	vim.cmd("vnew")
	scratch()
	vim.cmd("wincmd h")
end, { nargs = "?", complete = "filetype" })
