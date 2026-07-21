vim.pack.add({ "https://github.com/jay-babu/mason-nvim-dap.nvim" })
vim.pack.add({ "https://github.com/mfussenegger/nvim-dap" })

require("mason-nvim-dap").setup({
	-- Makes a best effort to setup the various debuggers with
	-- reasonable debug configurations
	automatic_installation = true,

	-- You can provide additional configuration to the handlers,
	-- see mason-nvim-dap README for more information
	handlers = {},

	-- You'll need to check that you have the required things installed
	-- online, please don't ask me how to install them :)
	ensure_installed = {
		-- Update this to ensure that you have the debuggers for the langs you want
		-- "delve",
	},
})

-- Change breakpoint icons
vim.api.nvim_set_hl(0, "DapBreak", { fg = "#e51400" })
vim.api.nvim_set_hl(0, "DapStop", { fg = "#ffcc00" })
local breakpoint_icons = vim.g.have_nerd_font
		and {
			Breakpoint = "",
			BreakpointCondition = "",
			BreakpointRejected = "",
			LogPoint = "",
			Stopped = "",
		}
	or { Breakpoint = "●", BreakpointCondition = "⊜", BreakpointRejected = "⊘", LogPoint = "◆", Stopped = "⭔" }
for type, icon in pairs(breakpoint_icons) do
	local tp = "Dap" .. type
	local hl = (type == "Stopped") and "DapStop" or "DapBreak"
	vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
end

require("dap").defaults.fallback.external_terminal = {
	command = "wt",
	args = { "-w", "0", "nt", "--" },
}

vim.keymap.set("n", "<F5>", function()
	require("dap").continue()
end, { desc = "Start/continue" })

vim.keymap.set("n", "<F10>", function()
	require("dap").step_over()
end, { desc = "Step over" })

vim.keymap.set("n", "<F11>", function()
	require("dap").step_into()
end, { desc = "Step into" })

vim.keymap.set("n", "<F12>", function()
	require("dap").step_out()
end, { desc = "Step out" })

vim.keymap.set("n", "<leader>db", function()
	require("dap").toggle_breakpoint()
end, { desc = "Toggle breakpoint" })

vim.keymap.set("n", "<leader>dB", function()
	require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Set breakpoint with condition" })

vim.keymap.set("n", "<leader>dC", function()
	require("dap").run_to_cursor()
end, { desc = "Run to cursor" })

vim.keymap.set("n", "<F7>", function()
	require("dapui").toggle()
end, { desc = "See last session result." })

local use_view = true
if use_view == true then
	vim.pack.add({ { src = "https://github.com/igorlfs/nvim-dap-view", version = vim.version.range("1.*") } })
	require("dap-view").setup({
		auto_toggle = true,
	})

	vim.keymap.set("n", "<leader>dh", "<cmd>DapViewHover!<cr>", { desc = "Debug hover" })
	vim.keymap.set("n", "<leader>dw", "<cmd>DapViewWatch<cr>", { desc = "Debug watch" })
	vim.keymap.set("n", "<leader>dt", "<cmd>DapViewToggle<cr>", { desc = "Debug watch" })

	local function focus_dap_view()
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			local bufnr = vim.api.nvim_win_get_buf(win)
			local ft = vim.bo[bufnr].filetype
			if ft == "dap-view" then
				vim.api.nvim_set_current_win(win)
				return
			end
		end

		vim.notify("No nvim-dap-view window found in current tab", vim.log.levels.WARN)
	end

	vim.keymap.set("n", "<leader>dv", focus_dap_view, { desc = "Focus nvim-dap-view" })
else
	vim.pack.add({ { src = "https://github.com/nvim-neotest/nvim-nio" } })
	vim.pack.add({ { src = "https://github.com/rcarriga/nvim-dap-ui" } })

	local dapui = require("dapui")
	-- Dap UI setup
	-- For more information, see |:help nvim-dap-ui|
	---@diagnostic disable-next-line: missing-fields
	dapui.setup({
		-- Set icons to characters that are more likely to work in every terminal.
		--    Feel free to remove or use ones that you like more! :)
		--    Don't feel like these are good choices.
		icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
		---@diagnostic disable-next-line: missing-fields
		controls = {
			icons = {
				pause = "⏸",
				play = "▶",
				step_into = "⏎",
				step_over = "⏭",
				step_out = "⏮",
				step_back = "b",
				run_last = "▶▶",
				terminate = "⏹",
				disconnect = "⏏",
			},
		},
		-- layouts = {
		-- 	{
		-- 		elements = {
		-- 			{ id = "easy-dotnet_cpu", size = 0.5 }, -- CPU usage panel (50% of layout)
		-- 			{ id = "easy-dotnet_mem", size = 0.5 }, -- Memory usage panel (50% of layout)
		-- 		},
		-- 		size = 35, -- Width of the sidebar
		-- 		position = "right",
		-- 	},
		-- },
	})

	local dap = require("dap")
	dap.listeners.after.event_initialized["dapui_config"] = dapui.open
	dap.listeners.before.event_terminated["dapui_config"] = dapui.close
	dap.listeners.before.event_exited["dapui_config"] = dapui.close

	vim.keymap.set("n", "<leader>dh", function()
		require("dapui").eval()
	end, { desc = "Debug hover" })
end
