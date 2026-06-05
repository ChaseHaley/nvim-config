local M = {}

local ns = vim.api.nvim_create_namespace("pack_inspect")
local results = {}
local check_buf
local inspect_ref = "refs/remotes/pack-inspect"
local inspect_tag_ref = "refs/pack-inspect/tags"

local function git(cwd, args, cb)
	vim.system(vim.list_extend({ "git", "-C", cwd }, args), { text = true }, function(result)
		vim.schedule(function()
			cb(result)
		end)
	end)
end

local function trim(value)
	local trimmed = (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
	return trimmed
end

local function short_rev(rev)
	if not rev or rev == "" then
		return "-------"
	end

	return rev:sub(1, 7)
end

local function commit_word(count)
	return count == 1 and "commit" or "commits"
end

local function plugin_name(plugin)
	return plugin.spec.name or vim.fs.basename(plugin.path) or plugin.spec.src
end

local function source_url(plugin)
	return plugin.spec and plugin.spec.src
end

local function web_url(plugin)
	local url = source_url(plugin)
	if not url or url == "" then
		return nil
	end

	url = trim(url)
	url = url:gsub("^git@([^:]+):", "https://%1/")
	url = url:gsub("^ssh://git@([^/]+)/", "https://%1/")
	url = url:gsub("^git://", "https://")
	url = url:gsub("%.git$", "")
	url = url:gsub("/$", "")
	url = url:gsub("^https://codeberg%.com/", "https://codeberg.org/")

	return url
end

local function commit_url(plugin, rev)
	local url = web_url(plugin)
	if not url or not rev or rev == "" then
		return nil
	end

	local host = url:match("^https?://([^/]+)") or ""
	if host:find("gitlab", 1, true) then
		return url .. "/-/commit/" .. rev
	end

	return url .. "/commit/" .. rev
end

local function commit_link(plugin, rev)
	local short = short_rev(rev)
	local url = commit_url(plugin, rev)
	if not url then
		return short
	end

	return ("[%s](%s)"):format(short, url)
end

local function target_ref(branch)
	return inspect_ref .. "/" .. branch
end

local function tag_ref(tag)
	return inspect_tag_ref .. "/" .. tag
end

local function display_target(target)
	local tag = target:gsub("^" .. vim.pesc(inspect_tag_ref) .. "/", "")
	if tag ~= target then
		return "tag " .. tag
	end

	local display = target:gsub("^" .. vim.pesc(inspect_ref) .. "/", "")
	if display == "HEAD" then
		return "remote HEAD"
	end

	return display
end

local function fetched_tags(plugin)
	local result = vim.system({
		"git",
		"-C",
		plugin.path,
		"for-each-ref",
		"--format=%(refname:strip=3)",
		inspect_tag_ref,
	}, { text = true }):wait()

	if result.code ~= 0 or trim(result.stdout) == "" then
		return plugin.tags or {}
	end

	return vim.split(trim(result.stdout), "\n", { plain = true })
end

local function version_range_target(plugin)
	local version = plugin.spec.version
	if type(version) ~= "table" or type(version.has) ~= "function" then
		return nil
	end

	local best_tag
	local best_version
	for _, tag in ipairs(fetched_tags(plugin)) do
		local version_text = tag:gsub("^v", "")
		local ok, parsed = pcall(vim.version.parse, version_text)
		if ok and parsed then
			local has_ok, has = pcall(function()
				return version:has(parsed)
			end)

			if has_ok and has and (not best_version or best_version < parsed) then
				best_tag = tag
				best_version = parsed
			end
		end
	end

	return best_tag and tag_ref(best_tag) or nil
end

local function target_candidates(plugin)
	local candidates = {}
	local version = plugin.spec.version
	local range_target = version_range_target(plugin)

	if range_target then
		candidates[#candidates + 1] = range_target
	end

	if type(version) == "string" and version ~= "" then
		candidates[#candidates + 1] = target_ref(version)
		candidates[#candidates + 1] = version
	end

	candidates[#candidates + 1] = "@{u}"
	candidates[#candidates + 1] = target_ref("HEAD")

	if type(plugin.branches) == "table" then
		for _, branch in ipairs(plugin.branches) do
			candidates[#candidates + 1] = target_ref(branch)
		end
	end

	candidates[#candidates + 1] = target_ref("main")
	candidates[#candidates + 1] = target_ref("master")

	local seen = {}
	local unique = {}
	for _, candidate in ipairs(candidates) do
		if not seen[candidate] then
			seen[candidate] = true
			unique[#unique + 1] = candidate
		end
	end

	return unique
end

local function fetch_plugin(plugin, cb)
	local src = source_url(plugin)
	if not src or src == "" then
		git(plugin.path, { "fetch", "--quiet", "--prune", "origin" }, cb)
		return
	end

	git(plugin.path, {
		"fetch",
		"--quiet",
		"--prune",
		src,
		"+refs/heads/*:" .. inspect_ref .. "/*",
		"+refs/tags/*:" .. inspect_tag_ref .. "/*",
		"+HEAD:" .. target_ref("HEAD"),
	}, cb)
end

local function open_url_under_cursor()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1
	local start = 1

	while true do
		local match_start, match_end, _, url = line:find("%[([^%]]-)%]%(([^%)]+)%)", start)
		if not match_start then
			break
		end

		if col >= match_start and col <= match_end then
			vim.ui.open(url)
			return
		end

		start = match_end + 1
	end

	start = 1
	while true do
		local match_start, match_end = line:find("https?://%S+", start)
		if not match_start then
			break
		end

		if col >= match_start and col <= match_end then
			local url = line:sub(match_start, match_end):gsub("[%)%]>%.,;:]+$", "")
			vim.ui.open(url)
			return
		end

		start = match_end + 1
	end

	local cfile = vim.fn.expand("<cfile>")
	if cfile:match("^https?://") then
		vim.ui.open(cfile)
	end
end

local function map_open_url(buf)
	vim.keymap.set("n", "gx", open_url_under_cursor, { buffer = buf, nowait = true, desc = "Open URL under cursor" })
end

local function scratch_buffer(name, filetype)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = true
	vim.bo[buf].filetype = filetype or ""
	vim.api.nvim_buf_set_name(buf, name)
	vim.cmd("botright split")
	vim.api.nvim_win_set_buf(0, buf)
	return buf
end

local function sorted_results()
	local items = vim.tbl_values(results)
	table.sort(items, function(a, b)
		if a.status ~= b.status then
			local order = { behind = 1, current = 2, checking = 3, error = 4 }
			return (order[a.status] or 99) < (order[b.status] or 99)
		end

		if (a.count or 0) ~= (b.count or 0) then
			return (a.count or 0) > (b.count or 0)
		end

		return a.name:lower() < b.name:lower()
	end)
	return items
end

local function line_for(item)
	if item.status == "checking" then
		return ("%-28s checking"):format(item.name)
	end

	if item.status == "current" then
		return ("%-28s current  %s"):format(item.name, commit_link(item.plugin, item.current))
	end

	if item.status == "behind" then
		return ("%-28s %3d %-7s  %s -> %s  %s"):format(
			item.name,
			item.count,
			commit_word(item.count),
			commit_link(item.plugin, item.current),
			commit_link(item.plugin, item.latest),
			display_target(item.target)
		)
	end

	return ("%-28s error    %s"):format(item.name, item.error or "unknown error")
end

local function render_check_buffer()
	if not check_buf or not vim.api.nvim_buf_is_valid(check_buf) then
		return
	end

	local lines = {
		"vim.pack updates",
		"",
		"<CR> log   gx open link   r refresh   q close",
		"",
	}

	local items = sorted_results()
	for _, item in ipairs(items) do
		lines[#lines + 1] = line_for(item)
	end

	vim.bo[check_buf].modifiable = true
	vim.api.nvim_buf_set_lines(check_buf, 0, -1, false, lines)
	vim.api.nvim_buf_clear_namespace(check_buf, ns, 0, -1)

	for i, item in ipairs(items) do
		local line = i + 3
		local hl = item.status == "behind" and "WarningMsg"
			or item.status == "error" and "ErrorMsg"
			or item.status == "current" and "Comment"
			or "Normal"
		vim.api.nvim_buf_add_highlight(check_buf, ns, hl, line, 0, -1)
	end

	vim.b[check_buf].pack_inspect_items = items
	vim.bo[check_buf].modifiable = false
end

local function set_error(plugin, message)
	results[plugin_name(plugin)] = {
		name = plugin_name(plugin),
		plugin = plugin,
		status = "error",
		error = message,
	}
	render_check_buffer()
end

local function resolve_target(plugin, candidates, index, cb)
	local candidate = candidates[index]
	if not candidate then
		cb(nil)
		return
	end

	git(plugin.path, { "rev-parse", "--verify", candidate .. "^{commit}" }, function(result)
		if result.code == 0 then
			cb(candidate)
			return
		end

		resolve_target(plugin, candidates, index + 1, cb)
	end)
end

local function inspect_plugin(plugin)
	local name = plugin_name(plugin)
	results[name] = {
		name = name,
		plugin = plugin,
		current = plugin.rev,
		status = "checking",
	}
	render_check_buffer()

	if vim.fn.executable("git") ~= 1 then
		set_error(plugin, "git executable not found")
		return
	end

	fetch_plugin(plugin, function(fetch_result)
		if fetch_result.code ~= 0 then
			set_error(plugin, trim(fetch_result.stderr) ~= "" and trim(fetch_result.stderr) or "git fetch failed")
			return
		end

		resolve_target(plugin, target_candidates(plugin), 1, function(target)
			if not target then
				set_error(plugin, "could not resolve update target")
				return
			end

			git(plugin.path, { "rev-list", "--count", "HEAD.." .. target }, function(count_result)
				if count_result.code ~= 0 then
					set_error(plugin, trim(count_result.stderr) ~= "" and trim(count_result.stderr) or "could not count commits")
					return
				end

				local count = tonumber(trim(count_result.stdout)) or 0
				git(plugin.path, { "rev-parse", target }, function(rev_result)
					local latest = rev_result.code == 0 and trim(rev_result.stdout) or ""
					results[name] = {
						name = name,
						plugin = plugin,
						current = plugin.rev,
						latest = latest,
						target = target,
						count = count,
						status = count > 0 and "behind" or "current",
					}
					render_check_buffer()
				end)
			end)
		end)
	end)
end

local function plugin_by_name(name)
	for _, plugin in ipairs(vim.pack.get()) do
		if plugin_name(plugin) == name then
			return plugin
		end
	end
end

local function item_under_cursor()
	local buf = vim.api.nvim_get_current_buf()
	local items = vim.b[buf].pack_inspect_items
	if not items then
		return nil
	end

	local line = vim.api.nvim_win_get_cursor(0)[1]
	return items[line - 4]
end

function M.names()
	local names = {}
	for _, plugin in ipairs(vim.pack.get()) do
		names[#names + 1] = plugin_name(plugin)
	end
	table.sort(names)
	return names
end

function M.check()
	results = {}
	check_buf = scratch_buffer("vim.pack updates", "markdown")

	vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = check_buf, nowait = true, desc = "Close pack updates" })
	vim.keymap.set("n", "r", M.check, { buffer = check_buf, nowait = true, desc = "Refresh pack updates" })
	map_open_url(check_buf)
	vim.keymap.set("n", "<CR>", function()
		local item = item_under_cursor()
		if item then
			M.log(item.name)
		end
	end, { buffer = check_buf, nowait = true, desc = "Show plugin update log" })

	render_check_buffer()

	for _, plugin in ipairs(vim.pack.get()) do
		inspect_plugin(plugin)
	end
end

function M.log(name)
	local cursor_item = not name and item_under_cursor() or nil
	local item = cursor_item or name and results[name]
	name = name or item and item.name

	local plugin = item and item.plugin or plugin_by_name(name)
	if not plugin then
		vim.notify(("Unknown plugin: %s"):format(name or ""), vim.log.levels.ERROR)
		return
	end

	local function open_log(target)
		git(plugin.path, { "log", "--format=%H%x09%s", "HEAD.." .. target }, function(result)
			if result.code ~= 0 then
				vim.notify(trim(result.stderr) ~= "" and trim(result.stderr) or "Could not read plugin log", vim.log.levels.ERROR)
				return
			end

			local lines = {}
			for _, line in ipairs(vim.split(trim(result.stdout), "\n", { plain = true })) do
				local rev, subject = line:match("^(%x+)%s(.*)$")
				if rev then
					lines[#lines + 1] = ("%s %s"):format(commit_link(plugin, rev), subject)
				end
			end

			if #lines == 0 then
				lines = { "No pending commits." }
			end

			if #lines == 1 and lines[1] == "" then
				lines = { "No pending commits." }
			end

			table.insert(lines, 1, "")
			table.insert(lines, 1, ("%s: HEAD..%s"):format(plugin_name(plugin), display_target(target)))

			local buf = scratch_buffer(("vim.pack log: %s"):format(plugin_name(plugin)), "markdown")
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
			vim.bo[buf].modifiable = false
			vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = buf, nowait = true, desc = "Close pack log" })
			map_open_url(buf)
		end)
	end

	if item and item.target then
		open_log(item.target)
		return
	end

	fetch_plugin(plugin, function(fetch_result)
		if fetch_result.code ~= 0 then
			vim.notify(trim(fetch_result.stderr) ~= "" and trim(fetch_result.stderr) or "git fetch failed", vim.log.levels.ERROR)
			return
		end

		resolve_target(plugin, target_candidates(plugin), 1, function(target)
			if not target then
				vim.notify("Could not resolve update target", vim.log.levels.ERROR)
				return
			end

			open_log(target)
		end)
	end)
end

function M.setup()
	vim.api.nvim_create_user_command("PackCheck", function()
		M.check()
	end, {})

	vim.api.nvim_create_user_command("PackLog", function(opts)
		M.log(opts.args ~= "" and opts.args or nil)
	end, {
		nargs = "?",
		complete = function()
			return M.names()
		end,
	})
end

return M
