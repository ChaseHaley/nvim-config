vim.g.DiffCharDoMapping = 0
vim.pack.add({ "https://github.com/rickhowe/diffchar.vim" })
vim.pack.add({ "https://github.com/dlyongemallo/diffview-plus.nvim" })

local codelens_guard = require("codelens_guard")
local open_views = 0

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
-- window, so an editing tab wins and a plugin tab never does.
local lib = require("diffview.lib")
local diffview_utils = require("diffview.utils")

local function has_file_window(tabpage)
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
		local buf = vim.api.nvim_win_get_buf(win)
		if
			vim.api.nvim_win_get_config(win).relative == ""
			and vim.bo[buf].buftype == ""
			and vim.bo[buf].buflisted
			and not vim.startswith(vim.bo[buf].filetype, "Neogit")
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
end)
vim.keymap.set("n", "<leader>gda", function ()
	diffview("DiffviewOpen")
end)
