-- Plugins installed here stay out of nvim-pack-lock.json, which vim.pack clones
-- in full on every machine that shares this config.
local M = {}

local root = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "optin", "opt")

--- Clones each repository on first use, then loads it with `:packadd`.
--- @param srcs string[]
function M.add(srcs)
	for _, src in ipairs(srcs) do
		local name = src:match("([^/\\]+)$"):gsub("%.git$", "")
		local path = vim.fs.joinpath(root, name)
		if not vim.uv.fs_stat(path) then
			vim.notify("Installing " .. name .. " from " .. src)
			local out = vim.system({ "git", "clone", "--filter=blob:none", src, path }, { text = true }):wait()
			if out.code ~= 0 then
				error(("git clone %s failed:\n%s"):format(src, out.stderr))
			end
		end
		vim.cmd.packadd(name)
	end
end

return M
