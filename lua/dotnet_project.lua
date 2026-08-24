-- Finds the solution or project Roslyn would open in the cwd. easy-dotnet uses
-- it to decide whether to load up front, and <leader>zoV uses it to pick what
-- to hand to Visual Studio.
--
-- Mirrors AutoLoadProjectsInitializer in dotnet/roslyn, which applies these
-- rules to the client's workspace folders, in order:
--   1. ".vscode/settings.json" holding "dotnet.defaultSolution": "disable"
--      loads nothing. Any other value names the solution, absolute or relative
--      to the folder, and a value naming a missing file falls through.
--   2. Exactly one .sln or .slnx in the folder itself opens that solution. Two
--      or more is ambiguous and falls through.
--   3. Any .csproj below the folder, searched recursively, opens as a project.
--      .fsproj and .vbproj are not searched, because Roslyn does not load them.
--
-- Two deliberate differences from the server. It reads settings.json as JSON,
-- which fails on the comments VS Code allows, so the value is read by pattern
-- instead. Its rule 3 recurses without limit or exclusions; this stops at
-- `max_depth` and skips build output, dependencies, and dot directories.

local max_depth = 6

-- AppData holds Windows per-user application state. Neovim's undo files live
-- there under names that encode the edited file's path, so they end in .csproj
-- and read as projects.
local ignored = { bin = true, obj = true, node_modules = true, AppData = true }

local function descend(name)
	return not ignored[name] and name:sub(1, 1) ~= "."
end

--- Absolute, with the separators the platform's own tools expect. devenv gets
--- these paths straight from `candidates`.
---@param path string
---@return string
local function absolute(path)
	local full = vim.fn.fnamemodify(path, ":p")
	if vim.fn.has("win32") == 0 then
		return full
	end
	return (full:gsub("/", "\\"))
end

---@param cwd string
---@return string? # "disable", a solution path, or nil when unset
local function default_solution(cwd)
	local settings = vim.fs.joinpath(cwd, ".vscode", "settings.json")
	if vim.fn.filereadable(settings) == 0 then
		return nil
	end
	return table.concat(vim.fn.readfile(settings), "\n"):match('"dotnet%.defaultSolution"%s*:%s*"([^"]*)"')
end

--- The solution named by settings.json, when it is set and the file exists.
---@param cwd string
---@return string?
local function named_solution(cwd)
	local name = default_solution(cwd)
	if not name or name == "disable" then
		return nil
	end

	local path = absolute(vim.fs.abspath(name))
	return vim.fn.filereadable(path) == 1 and path or nil
end

---@param cwd string
---@return string[]
local function solutions(cwd)
	local found = {}
	for name, kind in vim.fs.dir(cwd) do
		if kind == "file" and (name:match("%.sln$") or name:match("%.slnx$")) then
			found[#found + 1] = absolute(vim.fs.joinpath(cwd, name))
		end
	end
	return found
end

---@param cwd string
---@return string?
local function first_project(cwd)
	for path, kind in vim.fs.dir(cwd, { depth = max_depth, skip = descend }) do
		if kind == "file" and path:match("%.csproj$") then
			return absolute(vim.fs.joinpath(cwd, path))
		end
	end
	return nil
end

local M = {}

--- True when Roslyn's --autoLoadProjects would open a solution or project in
--- the cwd.
---@return boolean
function M.will_auto_load()
	local cwd = vim.uv.cwd()
	if default_solution(cwd) == "disable" then
		return false
	end

	return named_solution(cwd) ~= nil or #solutions(cwd) == 1 or first_project(cwd) ~= nil
end

--- Everything worth opening in the cwd: the solution named by settings.json,
--- or every solution at the top level, or the first project below it. Empty
--- when the cwd holds no .NET code. "disable" only stops Roslyn from loading a
--- solution, so it does not hide one here.
---@return string[]
function M.candidates()
	local cwd = vim.uv.cwd()

	local named = named_solution(cwd)
	if named then
		return { named }
	end

	local found = solutions(cwd)
	if #found > 0 then
		return found
	end

	local project = first_project(cwd)
	return project and { project } or {}
end

return M
