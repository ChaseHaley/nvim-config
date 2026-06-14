vim.api.nvim_create_user_command("CheckKey", "echo keytrans(getcharstr())", {})
vim.api.nvim_create_user_command("W", "w", {})
