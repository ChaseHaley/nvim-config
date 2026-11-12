require("loadout").add({ "https://github.com/dlyongemallo/diffview-plus.nvim" })

local codelens_guard = require("codelens_guard")
local open_views = 0

local function get_effective_bg(name, fallback)
	local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
	return (hl.reverse and hl.fg) or hl.bg or fallback
end

local function scale_color(color, factor)
	local scaled = 0
	for shift = 16, 0, -8 do
		local channel = math.floor(color / 2 ^ shift) % 256
		scaled = scaled * 256 + math.min(255, math.floor(channel * factor))
	end
	return scaled
end

local function set_codediff_highlights()
	local insert = get_effective_bg("DiffAdd", 0x1d3042)
	local delete = get_effective_bg("DiffDelete", 0x351d2b)
	local factor = vim.o.background == "light" and 0.92 or 1.4

	vim.api.nvim_set_hl(0, "DiffviewLineInsert", { bg = insert })
	vim.api.nvim_set_hl(0, "DiffviewLineDelete", { bg = delete })
	vim.api.nvim_set_hl(0, "DiffviewCharInsert", { bg = scale_color(insert, factor) })
	vim.api.nvim_set_hl(0, "DiffviewCharDelete", { bg = scale_color(delete, factor) })
	vim.api.nvim_set_hl(0, "DiffviewFiller", { fg = 0x444444 })
end

set_codediff_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("diffview-codediff-highlights", { clear = true }),
	callback = set_codediff_highlights,
})

local function codediff_side(line, char)
	return {
		DiffAdd = line,
		DiffChange = line,
		DiffText = char,
		DiffTextAdd = char,
		DiffDelete = "DiffviewFiller",
	}
end

local codediff_winhl = {
	diff2 = {
		a = codediff_side("DiffviewLineDelete", "DiffviewCharDelete"),
		b = codediff_side("DiffviewLineInsert", "DiffviewCharInsert"),
	},
	diff1_inline = {
		b = {
			DiffviewDiffAdd = "DiffviewLineInsert",
			DiffviewDiffChange = "DiffviewLineInsert",
			DiffviewDiffTextInline = "DiffviewCharInsert",
			DiffviewDiffDelete = "DiffviewLineDelete",
		},
	},
}

local function apply_codediff_highlights(ctx)
	local layout = ctx.layout_name:match("^diff2") and "diff2" or ctx.layout_name:match("^diff1_inline")
	local winhl = layout and codediff_winhl[layout][ctx.symbol]
	if winhl then
		vim.opt_local.winhighlight:append(winhl)
	end
end

require("diffview").setup(
	--- @type DiffviewConfig.user
	{
		file_panel = {
			win_config = {
				width = 60
			}
		},
		hooks = {
			diff_buf_win_enter = function(bufnr, winid, ctx)
				-- Re-trigger treesitter-context's on_attach evaluation.
				-- The group name is an internal detail of nvim-treesitter-context
				-- and may differ across versions; verify it matches your install
				-- or omit it to fire all BufReadPost handlers.
				-- `modeline = false` prevents `nvim_exec_autocmds`'s default
				-- post-autocmd modeline pass from running `:set` commands (e.g.
				-- `fileencoding`) against the diffview buffer, which is
				-- non-modifiable and would raise E21.
				pcall(vim.api.nvim_exec_autocmds, "BufReadPost", {
					buffer = bufnr,
					group = "treesitter_context_update",
					modeline = false,
				})

				codelens_guard.suppress(bufnr, "diffview")
				apply_codediff_highlights(ctx)
			end,
			view_opened = function()
				open_views = open_views + 1
			end,
			view_closed = function()
				local ok, tsc = pcall(require, "treesitter-context")
				if ok and tsc.enabled() then
					tsc.enable()
				end

				open_views = math.max(open_views - 1, 0)
				if open_views == 0 then
					codelens_guard.restore("diffview")
				end
			end,
		},
		hide_merge_artifacts = true,
		clean_up_buffers = true,
		enhanced_diff_hl = true,
		view = {
			one_sided_layout = "raw",
			cycle_layouts = {
				default = { "diff2_horizontal", "diff1_inline" },
			},
		},
		diffopt = { algorithm = "histogram" },
	}
)

-- The `goto_file*` actions pick their target through
-- `lib.get_prev_non_view_tabpage`, which accepts any tabpage Diffview does not
-- own — including the Neogit tab the view was launched from. Require a real file
-- window or an Oil window, so an editing or Oil tab wins and other plugin tabs
-- never do.
local lib = require("diffview.lib")
local diffview_utils = require("diffview.utils")

local function has_file_window(tabpage)
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
		local bo = vim.bo[vim.api.nvim_win_get_buf(win)]
		if
			vim.api.nvim_win_get_config(win).relative == ""
			and (
				bo.filetype == "oil"
				or (bo.buftype == "" and bo.buflisted and not vim.startswith(bo.filetype, "Neogit"))
			)
		then
			return true
		end
	end

	return false
end

lib.get_prev_non_view_tabpage = function()
	local seen = {}
	for _, view in ipairs(lib.views) do
		seen[view.tabpage] = true
	end

	local tabs = vim.api.nvim_list_tabpages()
	local prev = diffview_utils.tabnr_to_id(vim.fn.tabpagenr("#"))
	if prev then
		table.insert(tabs, 1, prev)
	end

	for _, id in ipairs(tabs) do
		if not seen[id] and has_file_window(id) then
			return id
		end
	end
end

local function diffview(cmd)
	local root = vim.fn.getcwd(-1, vim.fn.tabpagenr()) -- tab-local slot
	vim.cmd(cmd .. " -C" .. vim.fn.fnameescape(root))
end

vim.keymap.set("n", "<leader>gdf", "<cmd>DiffviewFileHistory --follow %<CR>")
vim.keymap.set("n", "<leader>gdf", function ()
	diffview("DiffviewFileHistory --follow %")
end, { desc = "File History" })
vim.keymap.set("n", "<leader>gda", function ()
	diffview("DiffviewOpen")
end, { desc = "Diff working tree" })

local working_tree = "(working tree)"

local function pick_diff_target(from, root)
	require("snacks").picker.pick({
		title = "Diff " .. from .. " to",
		cwd = root,
		multi = {
			{
				finder = function()
					return { { text = working_tree, working_tree = true } }
				end,
				format = "text",
				preview = function(ctx)
					ctx.preview:reset()
				end,
			},
			{
				source = "git_branches",
				all = true,
				win = { input = { keys = { ["<C-A>"] = false, ["<C-X>"] = false } } },
			},
			{ source = "git_log", cmd_args = { "--all" } },
		},
		sort = { fields = { "score:desc", "idx" } },
		confirm = function(picker, item)
			picker:close()
			if not item then
				return
			end
			diffview("DiffviewOpen " .. (item.working_tree and from or from .. ".." .. (item.branch or item.commit)))
		end,
	})
end

vim.keymap.set("n", "<leader>gdc", function()
	local root = vim.fn.getcwd(-1, vim.fn.tabpagenr())
	require("snacks").picker.git_log({
		title = "Diff from",
		cwd = root,
		cmd_args = { "--all" },
		confirm = function(picker, item)
			picker:close()
			if item then
				pick_diff_target(item.commit, root)
			end
		end,
	})
end, { desc = "Diff two commits" })
