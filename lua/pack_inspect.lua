local M = {}

local ns = vim.api.nvim_create_namespace("pack_inspect")
local results = {}
local check_buf
local check_line_items = {}
local check_line_sections = {}
local section_lines = {}
local folds_win
local place_cursor = false
local folded = { current = true }
local frozen
local checked_at
local log_win
local help_win
local marked = {}
local acked = {}
local acked_path = vim.fs.joinpath(vim.fn.stdpath("data"), "pack-inspect-acked.json")
local inspect_ref = "refs/remotes/pack-inspect"
local inspect_tag_ref = "refs/pack-inspect/tags"
local check_name = "vim.pack updates"
local render_queued = false
local reload_queued = false
local spawn_queue = {}
local spawn_running = false
local has_git

local sections = {
	{ key = "attention", title = "Needs attention" },
	{ key = "updates", title = "Updates" },
	{ key = "seen", title = "Seen" },
	{ key = "local", title = "Not checked" },
	{ key = "current", title = "Up to date" },
}

local section_rank = {}
for i, section in ipairs(sections) do
	section_rank[section.key] = i
end

local list_window_options = {
	number = false,
	relativenumber = false,
	signcolumn = "no",
	foldcolumn = "0",
	wrap = false,
	list = false,
	spell = false,
	conceallevel = 3,
	concealcursor = "nc",
}

local check_window_options = vim.tbl_extend("force", list_window_options, {
	cursorline = true,
	foldenable = true,
	foldmethod = "manual",
	foldtext = "",
})

local help_lines = {
	"Move and read",
	"  j k      move",
	"  <CR>     log, or fold a section",
	"  s        log in a new split",
	"  za       fold or open a section",
	"  gx       open the link under the cursor",
	"Update",
	"  <Tab>    mark or unmark the row for update",
	"  u        update the marked rows, else this one",
	"Act on the cursor row, or a V range",
	"  a        mark seen or unseen",
	"  c  C     check these, check all",
	"  L        sync to the lockfile",
	"  x        delete (not loaded only)",
	"Other",
	"  r  q  ?  reload, close, this help",
}

local function define_highlights()
	for name, link in pairs({
		PackCheckTitle = "Title",
		PackCheckNew = "WarningMsg",
		PackCheckSeen = "DiagnosticInfo",
		PackCheckAttention = "Constant",
		PackCheckError = "DiagnosticError",
		PackCheckCurrent = "DiagnosticOk",
		PackCheckChecking = "DiagnosticHint",
		PackCheckRef = "Directory",
		PackCheckDim = "Comment",
		PackCheckMarked = "Visual",
	}) do
		vim.api.nvim_set_hl(0, name, { link = link, default = true })
	end
end

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

local function load_acked()
	local ok, decoded = pcall(function()
		return vim.json.decode(table.concat(vim.fn.readfile(acked_path), "\n"))
	end)

	acked = (ok and type(decoded) == "table") and decoded or {}
end

local function save_acked()
	pcall(vim.fn.writefile, { vim.json.encode(acked) }, acked_path)
end

local function is_acked(item)
	return item.status == "behind" and item.latest ~= nil and acked[item.name] == item.latest
end

local function trim(value)
	local trimmed = (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
	return trimmed
end

local function first_line(value)
	return (value or ""):match("[^\r\n]+") or ""
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

local function ago(time)
	local seconds = os.time() - time
	if seconds < 45 then
		return "just now"
	end

	local minutes = math.floor(seconds / 60 + 0.5)
	if minutes < 60 then
		return minutes == 1 and "1 minute ago" or minutes .. " minutes ago"
	end

	local hours = math.floor(minutes / 60 + 0.5)
	return hours == 1 and "1 hour ago" or hours .. " hours ago"
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

local function target_ref(branch)
	return inspect_ref .. "/" .. branch
end

local function tag_ref(tag)
	return inspect_tag_ref .. "/" .. tag
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
	local ok, parsed = pcall(vim.version.parse, value, { strict = true })
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

local function is_version_range(version)
	return type(version) == "table" and type(version.has) == "function"
end

local function range_label(range)
	local from, to = range.from, range.to
	if from and not to and tostring(from) == "0.0.0" then
		return "any"
	end

	if from and to and from.minor == 0 and from.patch == 0 and to.major == from.major + 1 and to.minor == 0 and to.patch == 0 then
		return from.major .. ".x"
	end

	return tostring(range)
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

local function string_version_kind(target)
	if target:find("^" .. vim.pesc(inspect_tag_ref) .. "/") then
		return "tag"
	end

	if target:find("^" .. vim.pesc(inspect_ref) .. "/") then
		return "branch"
	end

	return "commit"
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

local function set_window_options(win, options)
	for name, value in pairs(options) do
		vim.api.nvim_set_option_value(name, value, { win = win, scope = "local" })
	end
end

local function keep_window_options(buf, options)
	vim.api.nvim_create_autocmd("BufWinEnter", {
		buffer = buf,
		callback = function()
			local win = vim.api.nvim_get_current_win()
			if vim.api.nvim_win_get_buf(win) == buf then
				set_window_options(win, options)
			end
		end,
	})
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

-- Links are written as markdown, `[text](url)`, so `gx` and a yanked line both
-- carry the URL; draw() conceals everything but the text.
local function new_line()
	return { text = "", width = 0, hls = {}, conceals = {} }
end

local function put(line, text, hl, url)
	local start = #line.text
	if url then
		line.text = ("%s[%s](%s)"):format(line.text, text, url)
		line.conceals[#line.conceals + 1] = { start, start + 1 }
		line.conceals[#line.conceals + 1] = { start + 1 + #text, #line.text }
		start = start + 1
	else
		line.text = line.text .. text
	end

	if hl and text ~= "" then
		line.hls[#line.hls + 1] = { start, start + #text, hl }
	end

	line.width = line.width + vim.api.nvim_strwidth(text)
	return line
end

local function pad_to(line, width)
	if line.width < width then
		put(line, string.rep(" ", width - line.width))
	end

	return line
end

local function fit(text, width)
	if vim.api.nvim_strwidth(text) <= width then
		return text
	end

	return vim.fn.strcharpart(text, 0, width - 1) .. "…"
end

local function draw(buf, lines, indent)
	indent = indent or ""
	local offset = #indent
	local text = {}
	for i, line in ipairs(lines) do
		text[i] = line.text == "" and "" or indent .. line.text
	end

	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)
	vim.bo[buf].modifiable = false
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

	for i, line in ipairs(lines) do
		local row = i - 1
		if line.line_hl then
			vim.api.nvim_buf_set_extmark(buf, ns, row, 0, { line_hl_group = line.line_hl })
		end

		for _, hl in ipairs(line.hls) do
			vim.api.nvim_buf_set_extmark(buf, ns, row, hl[1] + offset, { end_col = hl[2] + offset, hl_group = hl[3] })
		end

		for _, range in ipairs(line.conceals) do
			vim.api.nvim_buf_set_extmark(buf, ns, row, range[1] + offset, { end_col = range[2] + offset, conceal = "" })
		end
	end
end

local function section_of(item)
	if item.status == "behind" then
		return is_acked(item) and "seen" or "updates"
	end

	if item.status == "current" then
		return "current"
	end

	if item.status == "local" or item.status == "checking" then
		return "local"
	end

	return "attention"
end

local function sorted_results()
	local items = vim.tbl_values(results)
	table.sort(items, function(a, b)
		local rank_a, rank_b = section_rank[section_of(a)], section_rank[section_of(b)]
		if rank_a ~= rank_b then
			return rank_a < rank_b
		end

		if (a.count or 0) ~= (b.count or 0) then
			return (a.count or 0) > (b.count or 0)
		end

		return a.name:lower() < b.name:lower()
	end)
	return items
end

local function layout()
	local by_key = {}
	local placed = {}

	if frozen then
		for _, group in ipairs(frozen) do
			local items = {}
			for _, name in ipairs(group.names) do
				if results[name] then
					items[#items + 1] = results[name]
					placed[name] = true
				end
			end
			by_key[group.key] = items
		end
	end

	for _, item in ipairs(sorted_results()) do
		if not placed[item.name] then
			local key = section_of(item)
			by_key[key] = by_key[key] or {}
			table.insert(by_key[key], item)
		end
	end

	local groups = {}
	for _, section in ipairs(sections) do
		if by_key[section.key] and #by_key[section.key] > 0 then
			groups[#groups + 1] = { key = section.key, title = section.title, items = by_key[section.key] }
		end
	end

	return groups
end

local function freeze()
	if frozen then
		return
	end

	frozen = {}
	for _, group in ipairs(layout()) do
		local names = {}
		for i, item in ipairs(group.items) do
			names[i] = item.name
		end
		frozen[#frozen + 1] = { key = group.key, names = names }
	end
end

local function any_checking()
	for _, item in pairs(results) do
		if item.status == "checking" then
			return true
		end
	end

	return false
end

local function row_status(item)
	local status = item.status
	if status == "behind" then
		return "↑ " .. item.count, is_acked(item) and "PackCheckSeen" or "PackCheckNew"
	elseif status == "rollback" then
		return "↓ " .. item.dropped, "PackCheckAttention"
	elseif status == "diverged" then
		return "↕ " .. item.count, "PackCheckAttention"
	elseif status == "drift" then
		return "≠", "PackCheckAttention"
	elseif status == "error" then
		return "✗", "PackCheckError"
	elseif status == "checking" then
		return "…", "PackCheckChecking"
	elseif status == "current" then
		return "✓", "PackCheckCurrent"
	end

	return "·", "PackCheckDim"
end

local function ref_text(item)
	local version = spec_version(item.plugin)
	local info = item.target_info

	if is_version_range(version) then
		local label = range_label(version)
		return info and info.latest_allowed and (label .. "  " .. info.latest_allowed) or label
	end

	if type(version) == "string" and version ~= "" then
		return version
	end

	return info and info.target_label or ""
end

local function item_notes(item, loaded)
	local notes = {}
	local function add(text, hl)
		notes[#notes + 1] = { text, hl or "PackCheckDim" }
	end

	if is_acked(item) then
		add("seen", "PackCheckSeen")
	end

	if item.status == "rollback" then
		add(("update moves back %d %s"):format(item.dropped, commit_word(item.dropped)), "PackCheckAttention")
	elseif item.status == "diverged" then
		add(("%d new, %d dropped upstream"):format(item.count, item.dropped), "PackCheckAttention")
	elseif item.status == "drift" then
		add("disk differs from lockfile, L syncs", "PackCheckAttention")
	end

	if loaded == false then
		add("not loaded")
	end

	local info = item.target_info
	if info and info.blocked_label then
		add("newer " .. info.blocked_label)
	end

	if info and info.kind then
		add("pinned " .. info.kind)
	end

	return notes
end

local function item_line(item, columns, loaded)
	local line = new_line()
	put(line, marked[item.name] and "▌ " or "  ", "PackCheckRef")

	local glyph, hl = row_status(item)
	put(line, glyph, hl)
	pad_to(line, columns.name)
	put(line, item.name, nil, web_url(item.plugin))
	pad_to(line, columns.commits)

	if item.status == "error" then
		put(line, first_line(item.error), "PackCheckError")
		put(line, "  <CR> full error", "PackCheckDim")
		return line
	end

	local head = item.head or item.rev
	put(line, short_rev(head), "PackCheckDim", commit_url(item.plugin, head))

	local other = item.status == "drift" and item.rev
		or (item.status == "behind" or item.status == "rollback" or item.status == "diverged") and item.latest
	if other then
		put(line, item.status == "drift" and " ≠ " or " → ", "PackCheckDim")
		put(line, short_rev(other), hl, commit_url(item.plugin, other))
	end

	local ref = ref_text(item)
	local notes = item_notes(item, loaded)
	if ref ~= "" or #notes > 0 then
		pad_to(line, columns.ref)
		put(line, ref, "PackCheckRef")
	end

	if #notes > 0 then
		pad_to(line, columns.notes)
		for i, note in ipairs(notes) do
			if i > 1 then
				put(line, " · ", "PackCheckDim")
			end
			put(line, note[1], note[2])
		end
	end

	return line
end

local function header_line()
	local total, checking, unchecked, new, seen, attention = 0, 0, 0, 0, 0, 0
	for _, item in pairs(results) do
		total = total + 1
		local key = section_of(item)
		if item.status == "checking" then
			checking = checking + 1
		elseif key == "local" then
			unchecked = unchecked + 1
		elseif key == "updates" then
			new = new + 1
		elseif key == "seen" then
			seen = seen + 1
		elseif key == "attention" then
			attention = attention + 1
		end
	end

	local parts = {}
	if checking > 0 then
		parts[#parts + 1] = { ("checking %d/%d"):format(total - checking, total), "PackCheckChecking" }
	elseif unchecked == total then
		parts[#parts + 1] = { ("not checked yet, C checks all %d"):format(total), "PackCheckDim" }
	else
		parts[#parts + 1] = { new .. " new", new > 0 and "PackCheckNew" or "PackCheckDim" }
		parts[#parts + 1] = { seen .. " seen", seen > 0 and "PackCheckSeen" or "PackCheckDim" }
		if attention > 0 then
			parts[#parts + 1] = { attention .. " need attention", "PackCheckAttention" }
		end
		if checked_at then
			parts[#parts + 1] = { "checked " .. ago(checked_at), "PackCheckDim" }
		end
	end

	local marked_count = 0
	for name in pairs(marked) do
		if results[name] then
			marked_count = marked_count + 1
		end
	end
	if marked_count > 0 then
		parts[#parts + 1] = { marked_count .. " marked for update", "PackCheckRef" }
	end

	local line = new_line()
	put(line, "  ")
	put(line, "vim.pack", "PackCheckTitle")
	put(line, ("  %d plugins"):format(total))
	for _, part in ipairs(parts) do
		put(line, "  ·  ", "PackCheckDim")
		put(line, part[1], part[2])
	end
	put(line, "      ? help", "PackCheckDim")
	return line
end

local function section_line(group)
	local line = new_line()
	put(line, "  ")
	put(line, (folded[group.key] and "▸ " or "▾ ") .. group.title, "PackCheckTitle")
	put(line, "  " .. #group.items, "PackCheckDim")
	return line
end

local function footer_line()
	return put(
		new_line(),
		"  <CR> log  <Tab> mark for update  u update  a seen  c/C check  L lockfile  x delete  za fold  ? help",
		"PackCheckDim"
	)
end

local function sync_folds(win)
	if win ~= folds_win then
		return
	end

	vim.api.nvim_win_call(win, function()
		for key, lnum in pairs(section_lines) do
			folded[key] = vim.fn.foldclosed(lnum) ~= -1
		end
	end)
end

local function apply_folds(win, folds)
	if vim.wo[win].foldmethod ~= "manual" then
		return
	end

	vim.api.nvim_win_call(win, function()
		vim.cmd("normal! zE")
		for _, fold in ipairs(folds) do
			vim.cmd(("%d,%dfold"):format(fold.first, fold.last))
			vim.cmd(("%d%s"):format(fold.first, folded[fold.key] and "foldclose" or "foldopen"))
		end
	end)
end

local function render_check_buffer(focus)
	if not check_buf or not vim.api.nvim_buf_is_valid(check_buf) then
		return
	end

	local win = window_for_buf(check_buf)
	local cursor_key
	local cursor_col = 0
	if win then
		sync_folds(win)
		local pos = vim.api.nvim_win_get_cursor(win)
		local item = check_line_items[pos[1]]
		local section = check_line_sections[pos[1]]
		cursor_key = focus or item and item.name or section and ("section:" .. section)
		cursor_col = pos[2]
	end

	local loaded = {}
	for _, plugin in ipairs(vim.pack.get(nil, { info = false })) do
		loaded[plugin_name(plugin)] = plugin.active
	end

	local groups = layout()
	local name_width, ref_width = 20, 6
	for _, group in ipairs(groups) do
		for _, item in ipairs(group.items) do
			name_width = math.max(name_width, vim.api.nvim_strwidth(item.name) + 2)
			ref_width = math.max(ref_width, vim.api.nvim_strwidth(ref_text(item)) + 2)
		end
	end

	local columns = { name = 8, commits = 8 + name_width }
	columns.ref = columns.commits + 19
	columns.notes = columns.ref + ref_width

	local lines = { header_line(), new_line() }
	local line_items = {}
	local line_sections = {}
	local lines_by_section = {}
	local folds = {}
	for _, group in ipairs(groups) do
		lines[#lines + 1] = section_line(group)
		local first = #lines
		line_sections[first] = group.key
		lines_by_section[group.key] = first

		for _, item in ipairs(group.items) do
			local line = item_line(item, columns, loaded[item.name])
			line.line_hl = marked[item.name] and "PackCheckMarked" or nil
			lines[#lines + 1] = line
			line_items[#lines] = item
		end

		folds[#folds + 1] = { key = group.key, first = first, last = #lines }
		lines[#lines + 1] = new_line()
	end
	lines[#lines + 1] = footer_line()

	draw(check_buf, lines)
	check_line_items = line_items
	check_line_sections = line_sections
	section_lines = lines_by_section

	if not win then
		folds_win = nil
		return
	end

	apply_folds(win, folds)
	folds_win = win

	local target
	if place_cursor then
		place_cursor = false
		local first = folds[1]
		target = first and (folded[first.key] and first.first or first.first + 1)
	elseif cursor_key then
		for lnum, item in pairs(line_items) do
			if item.name == cursor_key then
				target = lnum
				break
			end
		end
		for lnum, key in pairs(line_sections) do
			if "section:" .. key == cursor_key then
				target = lnum
				break
			end
		end
	end

	if target then
		pcall(vim.api.nvim_win_set_cursor, win, { target, math.min(cursor_col, math.max(0, #lines[target].text - 1)) })
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

		if is_version_range(version) then
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
					kind = string_version_kind(target),
					target_label = version,
				})
			end)
			return
		end

		-- vim.pack follows the branch origin/HEAD named at clone time, even after
		-- the remote renames its default branch.
		git(plugin.path, { "rev-parse", "--abbrev-ref", "origin/HEAD" }, function(head_result)
			local branch = head_result.code == 0 and trim(head_result.stdout):gsub("^origin/", "") or ""
			local candidates = {}
			if branch ~= "" then
				candidates[#candidates + 1] = target_ref(branch)
			end
			candidates[#candidates + 1] = target_ref("HEAD")

			resolve_target(plugin, candidates, 1, function(target, sha)
				if not target then
					cb(nil, "could not resolve update target")
					return
				end

				cb({
					target = target,
					sha = sha,
					target_label = target == target_ref("HEAD") and "remote HEAD" or branch,
				})
			end)
		end)
	end)
end

local function inspect_plugin(plugin, on_result)
	local name = plugin_name(plugin)

	local function finish(item)
		results[name] = item
		if frozen and not any_checking() then
			frozen = nil
			checked_at = os.time()
		end
		schedule_render()
		if on_result then
			on_result(item)
		end
	end

	local function fail(message)
		finish({
			name = name,
			plugin = plugin,
			rev = plugin.rev,
			status = "error",
			error = message,
		})
	end

	local function stderr_or(result, fallback)
		return trim(result.stderr) ~= "" and trim(result.stderr) or fallback
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
			fail(stderr_or(fetch_result, "git fetch failed"))
			return
		end

		git(plugin.path, { "rev-parse", "HEAD" }, function(head_result)
			if head_result.code ~= 0 then
				fail(stderr_or(head_result, "could not read HEAD"))
				return
			end

			local head = trim(head_result.stdout)
			resolve_update_target(plugin, function(target_info, err)
				if not target_info then
					fail(err or "could not resolve update target")
					return
				end

				local target = target_info.target
				git(plugin.path, { "rev-list", "--left-right", "--count", "HEAD..." .. target }, function(count_result)
					if count_result.code ~= 0 then
						fail(stderr_or(count_result, "could not count commits"))
						return
					end

					local dropped, count = trim(count_result.stdout):match("^(%d+)%s+(%d+)$")
					dropped, count = tonumber(dropped) or 0, tonumber(count) or 0

					local status = "current"
					if head ~= plugin.rev then
						status = "drift"
					elseif count > 0 and dropped > 0 then
						status = "diverged"
					elseif count > 0 then
						status = "behind"
					elseif dropped > 0 then
						status = "rollback"
					end

					finish({
						name = name,
						plugin = plugin,
						rev = plugin.rev,
						head = head,
						latest = target_info.sha,
						target = target,
						target_info = target_info,
						count = count,
						dropped = dropped,
						status = status,
					})
				end)
			end)
		end)
	end)
end

local function check_items(items, on_result)
	freeze()
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

	if not previous or previous.status == "local" or previous.status == "drift" then
		return nil
	end

	if previous.rev == plugin.rev then
		previous.plugin = plugin
		return previous
	end

	if previous.latest and previous.latest == plugin.rev then
		return {
			name = name,
			plugin = plugin,
			rev = plugin.rev,
			head = plugin.rev,
			latest = plugin.rev,
			target = previous.target,
			target_info = previous.target_info,
			count = 0,
			dropped = 0,
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
				rev = plugin.rev,
				status = "local",
			}
	end

	for name in pairs(marked) do
		if not items[name] then
			marked[name] = nil
		end
	end

	for name in pairs(acked) do
		if not items[name] then
			acked[name] = nil
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

local function section_under_cursor()
	if vim.api.nvim_get_current_buf() ~= check_buf then
		return nil
	end

	return check_line_sections[vim.api.nvim_win_get_cursor(0)[1]]
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
	local buf = scratch_buffer("packcheck")
	keep_window_options(buf, list_window_options)
	table.insert(lines, 1, new_line())
	draw(buf, lines, "  ")

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

local function commit_line(plugin, commit, columns, hl)
	local subject = commit.subject
	local breaking = subject:match("^%w+!:") or subject:match("^%w+%b()!:") or subject:find("BREAKING CHANGE", 1, true)

	local line = new_line()
	put(line, short_rev(commit.rev), "PackCheckRef", commit_url(plugin, commit.rev))
	put(line, "  ")
	put(line, commit.age, "PackCheckDim")
	pad_to(line, columns.subject)
	put(line, fit(subject, 64), breaking and "PackCheckError" or hl)
	pad_to(line, columns.author)
	if breaking then
		put(line, "BREAKING  ", "PackCheckError")
	end
	put(line, commit.author, "PackCheckDim")
	return line
end

local function log_lines(plugin, output, head, target_sha, ref)
	local incoming = {}
	local dropped = {}
	local age_width, subject_width = 0, 0
	for _, row in ipairs(vim.split(trim(output), "\n", { plain = true })) do
		local side, rev, age, author, subject = row:match("^([<>])\t(%x+)\t([^\t]*)\t([^\t]*)\t(.*)$")
		if side then
			local list = side == ">" and incoming or dropped
			list[#list + 1] = { rev = rev, age = age, author = author, subject = subject }
			age_width = math.max(age_width, vim.api.nvim_strwidth(age))
			subject_width = math.max(subject_width, math.min(64, vim.api.nvim_strwidth(subject)))
		end
	end

	local columns = { subject = 9 + age_width + 2 }
	columns.author = columns.subject + subject_width + 2

	local title = new_line()
	put(title, plugin_name(plugin), "PackCheckTitle", web_url(plugin))
	put(title, "  ")
	put(title, short_rev(head), "PackCheckDim", commit_url(plugin, head))
	put(title, " → ", "PackCheckDim")
	put(title, short_rev(target_sha), "PackCheckNew", commit_url(plugin, target_sha))
	if ref ~= "" then
		put(title, "  ")
		put(title, ref, "PackCheckRef")
	end
	put(title, " · ", "PackCheckDim")
	put(title, ("%d %s"):format(#incoming, commit_word(#incoming)))
	if incoming[1] then
		put(title, " · newest " .. incoming[1].age, "PackCheckDim")
	end
	if #dropped > 0 then
		put(title, " · ", "PackCheckDim")
		put(title, ("%d dropped"):format(#dropped), "PackCheckAttention")
	end

	local lines = { title, new_line() }
	if #incoming == 0 and #dropped == 0 then
		lines[#lines + 1] = put(new_line(), "No pending commits.", "PackCheckDim")
	end

	for _, commit in ipairs(incoming) do
		lines[#lines + 1] = commit_line(plugin, commit, columns)
	end

	if #dropped > 0 then
		if #incoming > 0 then
			lines[#lines + 1] = new_line()
		end
		lines[#lines + 1] = put(new_line(), ("Dropped by this update  %d"):format(#dropped), "PackCheckAttention")
		for _, commit in ipairs(dropped) do
			lines[#lines + 1] = commit_line(plugin, commit, columns, "PackCheckAttention")
		end
	end

	return lines
end

local function show_help()
	if help_win and vim.api.nvim_win_is_valid(help_win) then
		vim.api.nvim_win_close(help_win, true)
		return
	end

	local lines = {}
	local width = 0
	for _, text in ipairs(help_lines) do
		local line = put(new_line(), " " .. text .. " ", not text:find("^ ") and "PackCheckTitle" or nil)
		width = math.max(width, line.width)
		lines[#lines + 1] = line
	end

	local buf = scratch_buffer("packcheck")
	draw(buf, lines)

	local parent = vim.api.nvim_get_current_win()
	help_win = vim.api.nvim_open_win(buf, true, {
		relative = "win",
		win = parent,
		anchor = "NE",
		row = 1,
		col = vim.api.nvim_win_get_width(parent) - 1,
		width = width,
		height = #lines,
		border = "rounded",
		title = " keys ",
		style = "minimal",
	})

	for _, lhs in ipairs({ "q", "<Esc>", "?" }) do
		vim.keymap.set("n", lhs, "<Cmd>close<CR>", { buffer = buf, nowait = true, desc = "Close PackCheck keys" })
	end

	local win = help_win
	vim.api.nvim_create_autocmd("WinLeave", {
		buffer = buf,
		once = true,
		callback = function()
			vim.schedule(function()
				pcall(vim.api.nvim_win_close, win, true)
			end)
		end,
	})
end

local function visual_items()
	local first, last = vim.fn.line("v"), vim.fn.line(".")
	if first > last then
		first, last = last, first
	end

	vim.cmd.normal({ args = { vim.keycode("<Esc>") }, bang = true })

	local items = {}
	for lnum = first, last do
		if check_line_items[lnum] then
			items[#items + 1] = check_line_items[lnum]
		end
	end
	return items
end

local function toggle_fold()
	pcall(vim.cmd, "normal! za")
	render_check_buffer()
end

local function map_check_keys(buf)
	local function map(lhs, rhs, desc, mode)
		vim.keymap.set(mode or "n", lhs, rhs, { buffer = buf, nowait = true, desc = desc })
	end

	local function on_range(action)
		return function()
			action(visual_items())
		end
	end

	local function log_under_cursor(split)
		return function()
			if section_under_cursor() then
				toggle_fold()
				return
			end

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
	end, "Check this plugin for updates")
	map("C", function()
		M.check_all()
	end, "Check every plugin for updates")
	map("u", function()
		M.update_selected()
	end, "Update the marked plugins, or this one")
	map("a", function()
		M.toggle_acked()
	end, "Mark a pending update as seen")
	map("L", function()
		M.sync_lockfile()
	end, "Sync this plugin to the lockfile")
	map("x", function()
		M.delete_selected()
	end, "Delete this plugin")
	map("<Tab>", function()
		M.toggle_marked()
	end, "Mark or unmark the plugin for update")
	map("<CR>", log_under_cursor(false), "Show plugin update log, or fold a section")
	map("s", log_under_cursor(true), "Show plugin update log in a new split")
	map("za", toggle_fold, "Fold or open a section")
	map("?", show_help, "Show PackCheck keys")

	map("<Tab>", on_range(M.toggle_marked), "Mark or unmark these plugins for update", "x")
	map("c", on_range(M.check_selected), "Check these plugins for updates", "x")
	map("u", on_range(M.update_selected), "Update these plugins", "x")
	map("a", on_range(M.toggle_acked), "Mark these pending updates as seen", "x")
	map("L", on_range(M.sync_lockfile), "Sync these plugins to the lockfile", "x")
	map("x", on_range(M.delete_selected), "Delete these plugins", "x")
	map_open_url(buf)
end

local function open_check_window()
	if not check_buf or not vim.api.nvim_buf_is_valid(check_buf) then
		check_buf = nofile_buf_named(check_name)
		if not check_buf then
			check_buf = scratch_buffer("packcheck")
			set_buf_name(check_buf, check_name)
		end

		vim.bo[check_buf].bufhidden = "hide"
		keep_window_options(check_buf, check_window_options)
		map_check_keys(check_buf)
	end

	local win = window_for_buf(check_buf)
	if win then
		vim.api.nvim_set_current_win(win)
		return
	end

	open_tab(check_buf)
	place_cursor = true
end

local function cursor_targets(items)
	if items then
		return items
	end

	local item = item_under_cursor()
	return item and { item } or {}
end

local function update_targets(items)
	if items or not next(marked) then
		return cursor_targets(items)
	end

	local targets = {}
	for name in pairs(marked) do
		if results[name] then
			targets[#targets + 1] = results[name]
		end
	end
	return targets
end

local function target_names(items)
	local names = {}
	for _, item in ipairs(items) do
		names[#names + 1] = item.name
	end
	return names
end

local function item_after(items)
	local targeted = {}
	for _, item in ipairs(items) do
		targeted[item.name] = true
	end

	local lnums = vim.tbl_keys(check_line_items)
	table.sort(lnums)

	local first, last
	for i, lnum in ipairs(lnums) do
		if targeted[check_line_items[lnum].name] then
			first = first or i
			last = i
		end
	end

	if not last then
		return nil
	end

	for i = last + 1, #lnums do
		local name = check_line_items[lnums[i]].name
		if not targeted[name] then
			return name
		end
	end

	for i = first - 1, 1, -1 do
		local name = check_line_items[lnums[i]].name
		if not targeted[name] then
			return name
		end
	end
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

function M.check_selected(items)
	items = cursor_targets(items)
	if #items == 0 then
		vim.notify("No plugin under the cursor", vim.log.levels.WARN)
		return
	end

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

	if item and item.status == "error" then
		local title = put(new_line(), plugin_name(plugin), "PackCheckTitle", web_url(plugin))
		local lines = { put(title, "  check failed", "PackCheckError"), new_line() }
		for _, text in ipairs(vim.split(item.error or "", "\n", { plain = true })) do
			lines[#lines + 1] = put(new_line(), text, "PackCheckError")
		end
		show_log(plugin, lines, opts.split)
		return
	end

	local function open_log(target, target_sha, head, ref)
		git(plugin.path, { "log", "--left-right", "--format=%m%x09%H%x09%cr%x09%an%x09%s", "HEAD..." .. target }, function(result)
			if result.code ~= 0 then
				vim.notify(trim(result.stderr) ~= "" and trim(result.stderr) or "Could not read plugin log", vim.log.levels.ERROR)
				return
			end

			show_log(plugin, log_lines(plugin, result.stdout, head, target_sha, ref), opts.split)
		end)
	end

	if item and item.status == "drift" then
		open_log(item.rev, item.rev, item.head, "lockfile")
		return
	end

	if item and item.target then
		open_log(item.target, item.latest, item.head or item.rev, ref_text(item))
		return
	end

	if item then
		check_items({ item }, function(checked)
			if checked.status == "error" or checked.target then
				M.log(checked.name, opts)
				return
			end

			vim.notify("Could not resolve update target", vim.log.levels.ERROR)
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

			open_log(target_info.target, target_info.sha, plugin.rev, ref_text({ plugin = plugin, target_info = target_info }))
		end)
	end)
end

function M.toggle_marked(items)
	if items then
		local mark = false
		for _, item in ipairs(items) do
			if not marked[item.name] then
				mark = true
				break
			end
		end

		for _, item in ipairs(items) do
			marked[item.name] = mark or nil
		end
		render_check_buffer()
		return
	end

	local item = item_under_cursor()
	if not item then
		return
	end

	marked[item.name] = not marked[item.name] or nil
	render_check_buffer()

	local win = vim.api.nvim_get_current_win()
	local pos = vim.api.nvim_win_get_cursor(win)
	local next_line = pos[1] + 1
	if check_line_items[next_line] then
		vim.api.nvim_win_set_cursor(win, { next_line, pos[2] })
	end
end

function M.toggle_acked(items)
	items = vim.tbl_filter(function(item)
		return item.status == "behind"
	end, cursor_targets(items))

	if #items == 0 then
		vim.notify("No pending update to mark", vim.log.levels.WARN)
		return
	end

	local mark = false
	for _, item in ipairs(items) do
		if not is_acked(item) then
			mark = true
			break
		end
	end

	local focus = item_after(items)
	for _, item in ipairs(items) do
		acked[item.name] = mark and item.latest or nil
		if mark then
			marked[item.name] = nil
		end
	end

	save_acked()
	render_check_buffer(focus)
end

function M.update_selected(items)
	items = update_targets(items)
	if #items == 0 then
		vim.notify("No plugin under the cursor", vim.log.levels.WARN)
		return
	end

	vim.pack.update(target_names(items), { target = "version" })
	render_check_buffer()
end

function M.sync_lockfile(items)
	items = vim.tbl_filter(function(item)
		return item.status == "drift"
	end, cursor_targets(items))

	if #items == 0 then
		vim.notify("No plugin here differs from the lockfile", vim.log.levels.WARN)
		return
	end

	vim.pack.update(target_names(items), { target = "lockfile" })
	render_check_buffer()
end

function M.delete_selected(items)
	items = cursor_targets(items)
	if #items == 0 then
		vim.notify("No plugin under the cursor", vim.log.levels.WARN)
		return
	end

	local loaded = {}
	for _, plugin in ipairs(installed_plugins()) do
		loaded[plugin_name(plugin)] = plugin.active
	end

	local names = {}
	local skipped = {}
	for _, item in ipairs(items) do
		if loaded[item.name] then
			skipped[#skipped + 1] = item.name
		else
			names[#names + 1] = item.name
		end
	end

	if #names == 0 then
		local one = #skipped == 1
		vim.notify(
			("%s %s loaded in this session. Remove %s from your config and restart, then press x."):format(
				table.concat(skipped, ", "),
				one and "is" or "are",
				one and "it" or "them"
			),
			vim.log.levels.WARN
		)
		return
	end

	local them = #names == 1 and "it" or "them"
	local prompt = ("Delete %s from disk?\nNot loaded in this session. If your config still adds %s, vim.pack installs %s again when that code runs."):format(
		table.concat(names, ", "),
		them,
		them
	)
	if #skipped > 0 then
		prompt = prompt .. ("\nSkipping %d loaded: %s."):format(#skipped, table.concat(skipped, ", "))
	end

	if vim.fn.confirm(prompt, "&Yes\n&No", 2) ~= 1 then
		return
	end

	local ok, err = pcall(vim.pack.del, names)
	if not ok then
		vim.notify(tostring(err), vim.log.levels.ERROR)
	end

	for _, name in ipairs(names) do
		results[name] = nil
		marked[name] = nil
	end
	render_check_buffer()
end

function M.setup()
	load_acked()
	define_highlights()

	local group = vim.api.nvim_create_augroup("pack_inspect", { clear = true })
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		desc = "Restore the pack updates highlight links",
		callback = define_highlights,
	})

	vim.api.nvim_create_autocmd("PackChanged", {
		group = group,
		desc = "Reload the pack updates panel after vim.pack changes a plugin",
		callback = function(ev)
			if ev.data.kind == "update" then
				marked[ev.data.spec.name] = nil
			end

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
