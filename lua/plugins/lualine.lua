vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim" })

local function is_file_window(win)
	return vim.api.nvim_win_get_config(win).relative == ""
		and vim.list_contains({ "", "acwrite" }, vim.bo[vim.api.nvim_win_get_buf(win)].buftype)
end

local function file_label(buf)
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" then
		return "[No Name]"
	end
	return vim.fn.fnamemodify((name:gsub("[/\\]$", "")), ":t")
end

local function tab_label(name, tab)
	if vim.t[tab.tabId].tabname then
		return name
	end
	if package.loaded["diffview.lib"] then
		for _, view in ipairs(require("diffview.lib").views) do
			if view.tabpage == tab.tabId then
				local history = require("diffview.scene.views.file_history.file_history_view").FileHistoryView
				return view:instanceof(history) and "File history" or "Diffview"
			end
		end
	end
	for _, winnr in ipairs({ vim.fn.tabpagewinnr(tab.tabnr), vim.fn.tabpagewinnr(tab.tabnr, "#") }) do
		local win = vim.fn.win_getid(winnr, tab.tabnr)
		if win ~= 0 and is_file_window(win) then
			return (file_label(vim.api.nvim_win_get_buf(win)):gsub("%%", "%%%%"))
		end
	end
	return name
end

require("lualine").setup({
	options = {
		icons_enabled = true,
		theme = "auto",
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			statusline = { "", "DiffviewFiles", "no-neck-pain" },
			winbar = { "" },
		},
		ignore_focus = {},
		always_divide_middle = true,
		always_show_tabline = true,
		globalstatus = false,
		refresh = {
			statusline = 1000,
			tabline = 1000,
			winbar = 1000,
			refresh_time = 16, -- ~60fps
			events = {
				"WinEnter",
				"BufEnter",
				"BufWritePost",
				"SessionLoadPost",
				"FileChangedShellPost",
				"VimResized",
				"Filetype",
				"CursorMoved",
				"CursorMovedI",
				"ModeChanged",
			},
		},
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff", "diagnostics" },
		lualine_c = { "filename" },
		lualine_x = { "encoding", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { "filename" },
		lualine_x = {},
		lualine_y = {},
		lualine_z = {},
	},
	tabline = {
		lualine_a = {
			{
				"tabs",
				mode = 1,
				max_length = function()
					return vim.o.columns
				end,
				fmt = tab_label,
			},
		},
		lualine_b = {},
		lualine_c = {},
		lualine_x = {},
		lualine_y = {},
		lualine_z = {},
	},
	winbar = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = {},
		lualine_x = {},
		lualine_y = {},
		lualine_z = {},
	},
	inactive_winbar = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = {},
		lualine_x = {},
		lualine_y = {},
		lualine_z = {},
	},
	extensions = { "oil", "mason" },
})
