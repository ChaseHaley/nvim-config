vim.g.DiffCharDoMapping = 0
vim.pack.add({ "https://github.com/rickhowe/diffchar.vim" })
vim.pack.add({ "https://github.com/dlyongemallo/diffview-plus.nvim" })

-- Neovim renders code lens as virtual lines above the declaration
-- (`virt_lines_above`). Vim's diff alignment only pads with filler lines for
-- real buffer lines, so every lens in the working-tree buffer shifts that pane
-- one row out of step with the git-side buffer, which has no LSP attached.
local codelens_group = vim.api.nvim_create_augroup("DiffviewCodelensGuard", { clear = true })
local codelens_guarded = {}
local codelens_was_enabled = {}
local open_views = 0

local function suppress_codelens(bufnr)
	-- easy-dotnet re-asserts `vim.lsp.codelens.enable(true, ...)` on BufEnter,
	-- CursorHold and InsertLeave, and registers those handlers from LspAttach —
	-- later than anything defined here, so they run after us and would always
	-- win. Deferring with `vim.schedule` lands our call after the event's whole
	-- autocmd chain has finished.
	local function off()
		vim.schedule(function()
			if not vim.api.nvim_buf_is_valid(bufnr) then
				return
			end
			if vim.lsp.codelens.is_enabled({ bufnr = bufnr }) then
				codelens_was_enabled[bufnr] = true
				vim.lsp.codelens.enable(false, { bufnr = bufnr })
			end
		end)
	end

	off()

	if codelens_guarded[bufnr] then
		return
	end
	codelens_guarded[bufnr] = true

	vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
		group = codelens_group,
		buffer = bufnr,
		callback = off,
	})
end

local function restore_codelens()
	vim.api.nvim_clear_autocmds({ group = codelens_group })

	for bufnr in pairs(codelens_was_enabled) do
		if vim.api.nvim_buf_is_valid(bufnr) then
			vim.lsp.codelens.enable(true, { bufnr = bufnr })
		end
	end

	codelens_guarded, codelens_was_enabled = {}, {}
end

require("diffview").setup(
	--- @type DiffviewConfig.user
	{
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

				suppress_codelens(bufnr)
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
					restore_codelens()
				end
			end,
		},
		hide_merge_artifacts = true,
		clean_up_buffers = true,
		enhanced_diff_hl = true,
		view = {
			one_sided_layout = "raw",
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
