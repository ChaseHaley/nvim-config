vim.pack.add({ "https://github.com/stevearc/resession.nvim" })
local resession = require("resession")

local LAST_SUFFIX = "_last"

--- Strips the resume suffix, so `<workspace>_last` maps back to `<workspace>`.
local function core_name(name)
	return (name:gsub(LAST_SUFFIX .. "$", ""))
end

resession.setup({
	-- scope.nvim unlists the buffers of every tab except the current one, so the
	-- default filter would drop those buffers and their windows from the session
	buf_filter = function(bufnr)
		local buftype = vim.bo[bufnr].buftype
		if buftype == "help" then
			return true
		end
		if buftype ~= "" and buftype ~= "acwrite" then
			return false
		end
		return vim.api.nvim_buf_get_name(bufnr) ~= ""
	end,
	extensions = {
		tabby = {},
		no_neck_pain = {},
		scope_tabs = {},
	},
})

--- Writes the current state as the core setup of the workspace.
--- @param new_session boolean If true, prompts for a new session name. If false, saves the current session if any.
local function save_core(new_session)
	if not new_session then
		local current = resession.get_current()
		if current then
			return resession.save(core_name(current))
		end
	end
	vim.ui.input({ prompt = "Session name: " }, function(name)
		if name and name ~= "" then
			resession.save(core_name(name))
		end
	end)
end

vim.keymap.set("n", "<leader>rs", save_core, { desc = "Save current or create new session" })
vim.keymap.set("n", "<leader>rn", function() save_core(true) end, { desc = "Create new session" })
vim.keymap.set("n", "<leader>rl", resession.load, { desc = "Load session" })
vim.keymap.set("n", "<leader>rd", resession.delete, { desc = "Delete session" })

vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		local current = resession.get_current()
		if current then
			resession.save(core_name(current) .. LAST_SUFFIX, { notify = false })
		end
	end,
})
