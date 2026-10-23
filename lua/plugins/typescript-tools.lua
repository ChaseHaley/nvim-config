require("loadout").add({ "https://github.com/pmizio/typescript-tools.nvim" })

local function read_major(package_json)
	local ok, pkg = pcall(vim.json.decode, table.concat(vim.fn.readfile(package_json), "\n"))
	local version = ok and type(pkg) == "table" and vim.version.parse(pkg.version or "")
	return version and version.major or 0
end

local global_major

local function get_global_major()
	if global_major == nil then
		local out = vim.fn.executable("tsc") == 1 and vim.system({ "tsc", "--version" }, { text = true }):wait()
		local version = out and out.code == 0 and vim.version.parse(out.stdout or "")
		global_major = version and version.major or 0
	end
	return global_major
end

-- TypeScript 7 is the native compiler: it serves editors only through
-- `tsc --lsp` and ships no tsserver.js, which typescript-tools needs. A project
-- uses its nearest node_modules install, or the `tsc` on PATH when it has none.
local function is_native(bufnr)
	for dir in vim.fs.parents(vim.api.nvim_buf_get_name(bufnr)) do
		local package_json = vim.fs.joinpath(dir, "node_modules", "typescript", "package.json")
		if vim.uv.fs_stat(package_json) then
			return read_major(package_json) >= 7
		end
	end
	return get_global_major() >= 7
end

require("typescript-tools").setup({
	root_dir = function(bufnr, on_dir)
		if not is_native(bufnr) then
			on_dir(require("typescript-tools.utils").get_root_dir(bufnr))
		end
	end,
})

local tsc_root_dir = vim.lsp.config.tsc.root_dir
vim.lsp.config("tsc", {
	root_dir = function(bufnr, on_dir)
		if is_native(bufnr) then
			tsc_root_dir(bufnr, on_dir)
		end
	end,
})
vim.lsp.enable("tsc")
