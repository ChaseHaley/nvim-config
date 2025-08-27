return {
	'copilotlsp-nvim/copilot-lsp',
	init = function()
		vim.g.copilot_nes_debounce = 500
		vim.lsp.enable 'copilot_ls'
		vim.keymap.set('n', '<Tab>', function()
			local bufnr = vim.api.nvim_get_current_buf()
			local state = vim.b[bufnr].nes_state
			if state then
				-- Try to jump to the start of the suggestion edit.
				-- If already at the start, then apply the pending suggestion and jump to the end of the edit.
				local _ = require('copilot-lsp.nes').walk_cursor_start_edit()
					or (require('copilot-lsp.nes').apply_pending_nes() and require('copilot-lsp.nes').walk_cursor_end_edit())
				return nil
			end
		end, { desc = 'Accept Copilot NES suggestion', expr = true })
		vim.keymap.set('n', '<Esc>', function()
			if not require('copilot-lsp.nes').clear() then
				vim.cmd('nohlsearch')
			end
		end, { desc = 'Clear Copilot NES suggestion' })
	end,
}
