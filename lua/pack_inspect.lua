local M = {}

local ns = vim.api.nvim_create_namespace("pack_inspect")
local results = {}
local check_buf
local check_line_items = {}
local log_win
local selected = {}
local inspect_ref = "refs/remotes/pack-inspect"
local inspect_tag_ref = "refs/pack-inspect/tags"
local check_name = "vim.pack updates"
local render_queued = false
local reload_queued = false
local spawn_queue = {}
local spawn_running = false
local has_git

-- vim.system() blocks the main loop for 6-20ms while it spawns, so a burst of
-- callbacks that each start more git work stalls the editor for hundreds of ms.
-- Start one process per loop iteration instead; the processes still run together.
local function pump_spawns()
	local start = table.remove(spawn_queue, 1)
	if not start then
		spawn_running = false
		return
	end

	start()
	vim.defer_fn(pump_spawns, 1)
end

local function git(cwd, args, cb)
	spawn_queue[#spawn_queue + 1] = function()
		vim.system(vim.list_extend({ "git", "-C", cwd }, args), { text = true }, function(result)
			vim.schedule(function()
				cb(result)
			end)
		end)
	end

	if not spawn_running then
		spawn_running = true
		vim.defer_fn(pump_spawns, 1)
	end
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

local function plugin_link(plugin)
	local name = plugin_name(plugin)
	local url = web_url(plugin)
	if not url then
		return name
	end

	return ("[%s](%s)"):format(name, url)
end

local function plugin_label(item)
	return plugin_link(item.plugin) .. string.rep(" ", math.max(1, 28 - #item.name))
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

local function unique_candidates(candidates)
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

local function parse_semver(value)
	local version_text = value:gsub("^v", "")
	local ok, parsed = pcall(vim.version.parse, version_text)
	if ok then
		return parsed
	end
end

local function version_range_has(range, version)
	local ok, has = pcall(function()
		return range:has(version)
	end)

	return ok and has
end

local function branch_semver(branch)
	local major, minor, patch = branch:match("^v?(%d+)%.(%d+)%.(%d+)$")
	if major then
		return vim.version.parse(("%s.%s.%s"):format(major, minor, patch))
	end

	major, minor = branch:match("^v?(%d+)%.(%d+)$")
	if major then
		return vim.version.parse(("%s.%s.0"):format(major, minor))
	end

	major = branch:match("^v?(%d+)$")
	if major then
		return vim.version.parse(("%s.0.0"):format(major))
	end
end

local function blocked_version_branch(branches, range, latest_allowed_version)
	local blocked

	for _, branch in ipairs(branches) do
		local parsed = branch_semver(branch)
		if parsed and not version_range_has(range, parsed) and (not latest_allowed_version or latest_allowed_version < parsed) then
			if not blocked or blocked.version < parsed then
				blocked = { label = branch .. " branch", version = parsed }
			end
		end
	end

	return blocked
end

local function spec_version(plugin)
	return plugin.spec and plugin.spec.version
end

local function spec_label(plugin)
	local version = spec_version(plugin)
	if type(version) == "table" and type(version.has) == "function" then
		return "version " .. tostring(version)
	end

	if type(version) == "string" and version ~= "" then
		return "version " .. version
	end

	return ""
end

local function version_range_info(plugin, remote)
	local version = spec_version(plugin)

	local latest_allowed_tag
	local latest_allowed_version
	local latest_tag
	local latest_version

	for _, tag in ipairs(remote.tags) do
		local parsed = parse_semver(tag)
		if parsed then
			if not latest_version or latest_version < parsed then
				latest_tag = tag
				latest_version = parsed
			end

			if version_range_has(version, parsed) and (not latest_allowed_version or latest_allowed_version < parsed) then
				latest_allowed_tag = tag
				latest_allowed_version = parsed
			end
		end
	end

	local blocked
	if latest_version and latest_tag and not version_range_has(version, latest_version) then
		blocked = { label = "tag " .. latest_tag, version = latest_version }
	end

	local branch_blocked = blocked_version_branch(remote.branches, version, latest_allowed_version)
	if branch_blocked and (not blocked or blocked.version < branch_blocked.version) then
		blocked = branch_blocked
	end

	local info = {
		restricted = true,
		version_label = tostring(version),
		latest_allowed = latest_allowed_tag,
		blocked_label = blocked and blocked.label or nil,
	}

	if not latest_allowed_tag then
		return info, "no tag matching version " .. tostring(version)
	end

	info.target = tag_ref(latest_allowed_tag)
	info.target_label = "tag " .. latest_allowed_tag
	return info
end

local function string_version_candidates(version)
	local candidates = {}
	candidates[#candidates + 1] = target_ref(version)
	candidates[#candidates + 1] = tag_ref(version)
	candidates[#candidates + 1] = version
	return unique_candidates(candidates)
end

local function string_version_label(version, target)
	if target:find("^" .. vim.pesc(inspect_tag_ref) .. "/") then
		return "tag " .. version
	end

	if target:find("^" .. vim.pesc(inspect_ref) .. "/") then
		return "branch " .. version
	end

	return "revision " .. version
end

local function default_target_candidates(remote)
	local candidates = {}
	candidates[#candidates + 1] = "@{u}"
	candidates[#candidates + 1] = target_ref("HEAD")

	for _, branch in ipairs(remote.branches) do
		candidates[#candidates + 1] = target_ref(branch)
	end

	candidates[#candidates + 1] = target_ref("main")
	candidates[#candidates + 1] = target_ref("master")

	return unique_candidates(candidates)
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

local function remote_info(plugin, cb)
	git(plugin.path, { "for-each-ref", "--format=%(refname)", inspect_tag_ref, inspect_ref }, function(result)
		local tags = {}
		local branches = {}

		for _, ref in ipairs(vim.split(trim(result.stdout), "\n", { plain = true })) do
			local tag = ref:match("^" .. vim.pesc(inspect_tag_ref) .. "/(.+)$")
			local branch = ref:match("^" .. vim.pesc(inspect_ref) .. "/(.+)$")
			if tag then
				tags[#tags + 1] = tag
			elseif branch then
				branches[#branches + 1] = branch
			end
		end

		cb({
			tags = #tags > 0 and tags or plugin.tags or {},
			branches = #branches > 0 and branches or plugin.branches or {},
		})
	end)
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

local function scratch_buffer(filetype)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = true
	vim.bo[buf].filetype = filetype or ""
	return buf
end

local function set_buf_name(buf, name)
	for attempt = 1, 9 do
		local candidate = attempt == 1 and name or ("%s (%d)"):format(name, attempt)
		if pcall(vim.api.nvim_buf_set_name, buf, candidate) then
			return
		end
	end
end

local function nofile_buf_named(name)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[buf].buftype == "nofile" and vim.fs.basename(vim.api.nvim_buf_get_name(buf)) == name then
			return buf
		end
	end
end

local function window_for_buf(buf)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == buf then
			return win
		end
	end
end

local function open_split(buf)
	vim.cmd("botright split")
	vim.api.nvim_win_set_buf(0, buf)
	return vim.api.nvim_get_current_win()
end

local function open_tab(buf)
	vim.cmd("$tab split")
	vim.api.nvim_win_set_buf(0, buf)
	return vim.api.nvim_get_current_win()
end

local function sorted_results()
	local items = vim.tbl_values(results)
	table.sort(items, function(a, b)
		if a.status ~= b.status then
			local order = { behind = 1, ["local"] = 2, checking = 3, current = 4, error = 5 }
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
	local function summary(include_default)
		local target_info = item.target_info
		if not target_info then
			return include_default and display_target(item.target) or ""
		end

		if target_info.restricted then
			local parts = { "restricted " .. target_info.version_label }
			if target_info.latest_allowed then
				parts[#parts + 1] = "target " .. target_info.latest_allowed
			elseif target_info.target_label then
				parts[#parts + 1] = "target " .. target_info.target_label
			end

			if target_info.blocked_label then
				parts[#parts + 1] = "newer " .. target_info.blocked_label .. " outside range"
			end

			return table.concat(parts, "; ")
		end

		if target_info.explicit then
			return "version " .. target_info.target_label
		end

		return include_default and target_info.target_label or ""
	end

	if item.status == "checking" then
		return plugin_label(item) .. "checking"
	end

	if item.status == "local" then
		local detail = spec_label(item.plugin)
		if detail ~= "" then
			return ("%slocal    %s  %s"):format(plugin_label(item), commit_link(item.plugin, item.current), detail)
		end

		return ("%slocal    %s"):format(plugin_label(item), commit_link(item.plugin, item.current))
	end

	if item.status == "current" then
		local detail = summary(false)
		if detail ~= "" then
			return ("%scurrent  %s  %s"):format(plugin_label(item), commit_link(item.plugin, item.current), detail)
		end

		return ("%scurrent  %s"):format(plugin_label(item), commit_link(item.plugin, item.current))
	end

	if item.status == "behind" then
		return ("%s%3d %-7s  %s -> %s  %s"):format(
			plugin_label(item),
			item.count,
			commit_word(item.count),
			commit_link(item.plugin, item.current),
			commit_link(item.plugin, item.latest),
			summary(true)
		)
	end

	return ("%serror    %s"):format(plugin_label(item), item.error or "unknown error")
end

local function status_counts()
	local counts = { total = 0 }
	for _, item in pairs(results) do
		counts.total = counts.total + 1
		counts[item.status] = (counts[item.status] or 0) + 1
	end

	return counts
end

local function header_lines()
	local counts = status_counts()
	local title = ("vim.pack updates  %d plugins"):format(counts.total)

	if (counts.behind or 0) > 0 then
		title = title .. ("  %d behind"):format(counts.behind)
	end

	if (counts.error or 0) > 0 then
		title = title .. ("  %d failed"):format(counts.error)
	end

	if (counts.checking or 0) > 0 then
		title = title .. ("  checking %d"):format(counts.checking)
	end

	return {
		title,
		"",
		"<CR> log   s log in split   <Tab> select   c check   C check all",
		"u update   x delete   r reload   q close",
		"",
	}
end

local function render_check_buffer()
	if not check_buf or not vim.api.nvim_buf_is_valid(check_buf) then
		return
	end

	local win = window_for_buf(check_buf)
	local cursor_name
	local cursor_col = 0
	if win then
		local pos = vim.api.nvim_win_get_cursor(win)
		local current = check_line_items[pos[1]]
		cursor_name = current and current.name
		cursor_col = pos[2]
	end

	local lines = header_lines()

	local active_items = {}
	local inactive_items = {}
	for _, item in ipairs(sorted_results()) do
		if item.plugin.active == false then
			inactive_items[#inactive_items + 1] = item
		else
			active_items[#active_items + 1] = item
		end
	end

	local line_items = {}
	local highlights = { [1] = "Title", [3] = "Comment", [4] = "Comment" }

	local function append_item(item)
		local mark = selected[item.name] and "> " or "  "
		lines[#lines + 1] = mark .. line_for(item)
		line_items[#lines] = item
		if selected[item.name] then
			highlights[#lines] = "Visual"
		else
			highlights[#lines] = item.status == "behind" and "WarningMsg"
				or item.status == "error" and "ErrorMsg"
				or item.status == "current" and "Comment"
				or "Normal"
		end
	end

	for _, item in ipairs(active_items) do
		append_item(item)
	end

	if #inactive_items > 0 then
		lines[#lines + 1] = ""
		lines[#lines + 1] = "-- inactive --"
		highlights[#lines] = "Title"
		for _, item in ipairs(inactive_items) do
			append_item(item)
		end
	end

	vim.bo[check_buf].modifiable = true
	vim.api.nvim_buf_set_lines(check_buf, 0, -1, false, lines)
	vim.api.nvim_buf_clear_namespace(check_buf, ns, 0, -1)

	for line, hl in pairs(highlights) do
		vim.api.nvim_buf_add_highlight(check_buf, ns, hl, line - 1, 0, -1)
	end

	check_line_items = line_items
	vim.bo[check_buf].modifiable = false

	if win and cursor_name then
		for line, item in pairs(line_items) do
			if item.name == cursor_name then
				pcall(vim.api.nvim_win_set_cursor, win, { line, math.min(cursor_col, math.max(0, #lines[line] - 1)) })
				break
			end
		end
	end
end

local function schedule_render()
	if render_queued then
		return
	end

	render_queued = true
	vim.schedule(function()
		render_queued = false
		render_check_buffer()
	end)
end

local function resolve_target(plugin, candidates, index, cb)
	local candidate = candidates[index]
	if not candidate then
		cb(nil)
		return
	end

	git(plugin.path, { "rev-parse", "--verify", candidate .. "^{commit}" }, function(result)
		if result.code == 0 then
			cb(candidate, trim(result.stdout))
			return
		end

		resolve_target(plugin, candidates, index + 1, cb)
	end)
end

local function resolve_update_target(plugin, cb)
	remote_info(plugin, function(remote)
		local version = spec_version(plugin)

		if type(version) == "table" and type(version.has) == "function" then
			local target_info, err = version_range_info(plugin, remote)
			if not target_info or not target_info.target then
				cb(nil, err or "could not resolve version range")
				return
			end

			resolve_target(plugin, { target_info.target }, 1, function(target, sha)
				if not target then
					cb(nil, "could not resolve " .. target_info.target_label)
					return
				end

				target_info.target = target
				target_info.sha = sha
				cb(target_info)
			end)
			return
		end

		if type(version) == "string" and version ~= "" then
			resolve_target(plugin, string_version_candidates(version), 1, function(target, sha)
				if not target then
					cb(nil, "could not resolve version " .. version)
					return
				end

				cb({
					explicit = true,
					version_label = version,
					target = target,
					sha = sha,
					target_label = string_version_label(version, target),
				})
			end)
			return
		end

		resolve_target(plugin, default_target_candidates(remote), 1, function(target, sha)
			if not target then
				cb(nil, "could not resolve update target")
				return
			end

			cb({
				target = target,
				sha = sha,
				target_label = display_target(target),
			})
		end)
	end)
end

local function inspect_plugin(plugin, on_result)
	local name = plugin_name(plugin)

	local function finish(item)
		results[name] = item
		schedule_render()
		if on_result then
			on_result(item)
		end
	end

	local function fail(message)
		finish({
			name = name,
			plugin = plugin,
			current = plugin.rev,
			status = "error",
			error = message,
		})
	end

	if has_git == nil then
		has_git = vim.fn.executable("git") == 1
	end

	if not has_git then
		fail("git executable not found")
		return
	end

	fetch_plugin(plugin, function(fetch_result)
		if fetch_result.code ~= 0 then
			fail(trim(fetch_result.stderr) ~= "" and trim(fetch_result.stderr) or "git fetch failed")
			return
		end

		resolve_update_target(plugin, function(target_info, err)
			if not target_info then
				fail(err or "could not resolve update target")
				return
			end

			local target = target_info.target
			git(plugin.path, { "rev-list", "--count", "HEAD.." .. target }, function(count_result)
				if count_result.code ~= 0 then
					fail(trim(count_result.stderr) ~= "" and trim(count_result.stderr) or "could not count commits")
					return
				end

				local count = tonumber(trim(count_result.stdout)) or 0
				finish({
					name = name,
					plugin = plugin,
					current = plugin.rev,
					latest = target_info.sha,
					target = target,
					target_info = target_info,
					count = count,
					status = count > 0 and "behind" or "current",
				})
			end)
		end)
	end)
end

local function check_items(items, on_result)
	for _, item in ipairs(items) do
		item.status = "checking"
	end

	render_check_buffer()

	for _, item in ipairs(items) do
		inspect_plugin(item.plugin, on_result)
	end
end

local function installed_plugins()
	return vim.pack.get(nil, { info = false })
end

local function plugin_by_name(name)
	for _, plugin in ipairs(installed_plugins()) do
		if plugin_name(plugin) == name then
			return plugin
		end
	end
end

local function reloaded_item(plugin, previous)
	local name = plugin_name(plugin)

	if not previous or previous.status == "local" then
		return nil
	end

	if previous.current == plugin.rev then
		previous.plugin = plugin
		return previous
	end

	if previous.latest and previous.latest == plugin.rev then
		return {
			name = name,
			plugin = plugin,
			current = plugin.rev,
			latest = plugin.rev,
			target = previous.target,
			target_info = previous.target_info,
			count = 0,
			status = "current",
		}
	end
end

local function load_plugins()
	local items = {}
	for _, plugin in ipairs(installed_plugins()) do
		local name = plugin_name(plugin)
		items[name] = reloaded_item(plugin, results[name])
			or {
				name = name,
				plugin = plugin,
				current = plugin.rev,
				status = "local",
			}
	end

	for name in pairs(selected) do
		if not items[name] then
			selected[name] = nil
		end
	end

	results = items
end

local function schedule_reload()
	if reload_queued then
		return
	end

	reload_queued = true
	vim.schedule(function()
		reload_queued = false
		load_plugins()
		render_check_buffer()
	end)
end

local function item_under_cursor()
	local buf = vim.api.nvim_get_current_buf()
	if buf ~= check_buf then
		return nil
	end

	local line = vim.api.nvim_win_get_cursor(0)[1]
	return check_line_items[line]
end

local function reusable_log_win()
	if not log_win or not vim.api.nvim_win_is_valid(log_win) then
		return nil
	end

	if vim.api.nvim_win_get_tabpage(log_win) ~= vim.api.nvim_get_current_tabpage() then
		return nil
	end

	if vim.api.nvim_win_get_buf(log_win) == check_buf then
		return nil
	end

	return log_win
end

local function show_log(plugin, lines, split)
	local buf = scratch_buffer("markdown")
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false

	local win = not split and reusable_log_win()
	if win then
		vim.api.nvim_win_set_buf(win, buf)
		vim.api.nvim_set_current_win(win)
	else
		log_win = open_split(buf)
	end

	set_buf_name(buf, ("vim.pack log: %s"):format(plugin_name(plugin)))
	vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = buf, nowait = true, desc = "Close pack log" })
	map_open_url(buf)
end

local function map_check_keys(buf)
	local function map(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, desc = desc })
	end

	local function log_under_cursor(split)
		return function()
			local item = item_under_cursor()
			if item then
				M.log(item.name, { split = split })
			end
		end
	end

	map("q", function()
		if #vim.api.nvim_list_wins() > 1 then
			vim.cmd("close")
		end
	end, "Close pack updates")
	map("r", function()
		M.reload()
	end, "Reload installed plugins")
	map("c", function()
		M.check_selected()
	end, "Check selected plugins for updates")
	map("C", function()
		M.check_all()
	end, "Check every plugin for updates")
	map("u", function()
		M.update_selected()
	end, "Update selected plugin")
	map("x", function()
		M.delete_selected()
	end, "Delete selected plugin")
	map("<Tab>", function()
		M.toggle_selected()
	end, "Toggle plugin selection")
	map("<CR>", log_under_cursor(false), "Show plugin update log")
	map("s", log_under_cursor(true), "Show plugin update log in a new split")
	map_open_url(buf)
end

local function open_check_window()
	if not check_buf or not vim.api.nvim_buf_is_valid(check_buf) then
		check_buf = nofile_buf_named(check_name)
		if not check_buf then
			check_buf = scratch_buffer("markdown")
			set_buf_name(check_buf, check_name)
		end

		vim.bo[check_buf].bufhidden = "hide"
		map_check_keys(check_buf)
	end

	local win = window_for_buf(check_buf)
	if win then
		vim.api.nvim_set_current_win(win)
		return
	end

	open_tab(check_buf)
end

local function selected_targets()
	if next(selected) then
		local items = {}
		for name in pairs(selected) do
			if results[name] then
				items[#items + 1] = results[name]
			end
		end
		return items
	end

	local item = item_under_cursor()
	return item and { item } or {}
end

local function target_names(items)
	local names = {}
	for _, item in ipairs(items) do
		names[#names + 1] = item.name
	end
	return names
end

function M.names()
	local names = {}
	for _, plugin in ipairs(installed_plugins()) do
		names[#names + 1] = plugin_name(plugin)
	end
	table.sort(names)
	return names
end

function M.check(opts)
	opts = opts or {}
	load_plugins()
	open_check_window()
	render_check_buffer()

	if opts.fetch then
		M.check_all()
	end
end

function M.reload()
	load_plugins()
	render_check_buffer()
end

function M.check_all()
	check_items(sorted_results())
end

function M.check_selected()
	local items = selected_targets()
	if #items == 0 then
		vim.notify("No plugin selected", vim.log.levels.WARN)
		return
	end

	selected = {}
	check_items(items)
end

function M.log(name, opts)
	opts = opts or {}
	local cursor_item = not name and item_under_cursor() or nil
	local item = cursor_item or (name and results[name])
	name = name or (item and item.name)

	local plugin = item and item.plugin or plugin_by_name(name)
	if not plugin then
		vim.notify(("Unknown plugin: %s"):format(name or ""), vim.log.levels.ERROR)
		return
	end

	local function log_target_label(target, target_info)
		if not target_info then
			return display_target(target)
		end

		if target_info.restricted then
			return target_info.target_label .. " (restricted " .. target_info.version_label .. ")"
		end

		if target_info.explicit then
			return "version " .. target_info.target_label
		end

		return target_info.target_label
	end

	local function open_log(target, target_info)
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
			table.insert(lines, 1, ("%s: HEAD..%s"):format(plugin_link(plugin), log_target_label(target, target_info)))

			show_log(plugin, lines, opts.split)
		end)
	end

	if item and item.target then
		open_log(item.target, item.target_info)
		return
	end

	if item then
		check_items({ item }, function(checked)
			if checked and checked.target then
				open_log(checked.target, checked.target_info)
				return
			end

			vim.notify(checked and checked.error or "Could not resolve update target", vim.log.levels.ERROR)
		end)
		return
	end

	fetch_plugin(plugin, function(fetch_result)
		if fetch_result.code ~= 0 then
			vim.notify(trim(fetch_result.stderr) ~= "" and trim(fetch_result.stderr) or "git fetch failed", vim.log.levels.ERROR)
			return
		end

		resolve_update_target(plugin, function(target_info, err)
			if not target_info then
				vim.notify(err or "Could not resolve update target", vim.log.levels.ERROR)
				return
			end

			open_log(target_info.target, target_info)
		end)
	end)
end

function M.toggle_selected()
	local item = item_under_cursor()
	if not item then
		return
	end

	selected[item.name] = not selected[item.name] or nil
	render_check_buffer()

	local win = vim.api.nvim_get_current_win()
	local pos = vim.api.nvim_win_get_cursor(win)
	local next_line = pos[1] + 1
	if check_line_items[next_line] then
		vim.api.nvim_win_set_cursor(win, { next_line, pos[2] })
	end
end

function M.update_selected()
	local items = selected_targets()
	if #items == 0 then
		vim.notify("No plugin selected", vim.log.levels.WARN)
		return
	end

	vim.pack.update(target_names(items), { target = "version" })
	selected = {}
	render_check_buffer()
end

function M.delete_selected()
	local items = selected_targets()
	if #items == 0 then
		vim.notify("No plugin selected", vim.log.levels.WARN)
		return
	end

	local names = target_names(items)
	local prompt = ("Delete %d plugin(s)?\n%s"):format(#names, table.concat(names, ", "))
	if vim.fn.confirm(prompt, "&Yes\n&No", 2) ~= 1 then
		return
	end

	vim.pack.del(names)
	for _, name in ipairs(names) do
		results[name] = nil
		selected[name] = nil
	end
	render_check_buffer()
end

function M.setup()
	vim.api.nvim_create_autocmd("PackChanged", {
		group = vim.api.nvim_create_augroup("pack_inspect", { clear = true }),
		desc = "Reload the pack updates panel after vim.pack changes a plugin",
		callback = function()
			if check_buf and vim.api.nvim_buf_is_valid(check_buf) then
				schedule_reload()
			end
		end,
	})

	vim.api.nvim_create_user_command("PackCheck", function(opts)
		M.check({ fetch = opts.bang })
	end, { bang = true, desc = "Show vim.pack plugins; ! also checks for updates" })

	vim.api.nvim_create_user_command("PackLog", function(opts)
		M.log(opts.args ~= "" and opts.args or nil, { split = opts.bang })
	end, {
		nargs = "?",
		bang = true,
		desc = "Show a plugin's pending update log",
		complete = function()
			return M.names()
		end,
	})
end

return M
