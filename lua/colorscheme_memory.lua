local M = {}

local saved_path = vim.fs.joinpath(vim.fn.stdpath("data"), "colorscheme")

local function follow_aiodev()
	if vim.env.AIODEV_CLI then
		require("aiodev_theme").setup()
	end
end

--- Applies the colorscheme last picked in the colorscheme picker. Follows the AIODev theme
--- instead when the pick was "aiodev", nothing was picked yet, or the pick no longer loads.
function M.restore()
	local name = vim.fn.filereadable(saved_path) == 1 and vim.fn.readfile(saved_path)[1]
	if name and name ~= "aiodev" and pcall(vim.cmd.colorscheme, name) then
		return
	end
	follow_aiodev()
end

--- Saves a colorscheme picked in the colorscheme picker for the next session.
---@param name string
function M.remember(name)
	vim.fn.writefile({ name }, saved_path)
	if name == "aiodev" then
		follow_aiodev()
	end
end

return M
