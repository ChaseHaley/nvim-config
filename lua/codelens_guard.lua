-- Neovim renders code lens as virtual lines above the declaration
-- (`virt_lines_above`). Views that line a buffer up row for row with another
-- window, such as a diff or a scrollbound blame panel, only pad for real buffer
-- lines, so every lens shifts that window one row out of step.
local M = {}

local group = vim.api.nvim_create_augroup("CodelensGuard", { clear = true })
--- @type table<integer, table<any, true>>
local owners = {}
--- @type table<integer, true>
local was_enabled = {}

local function off(bufnr)
	-- easy-dotnet re-asserts `vim.lsp.codelens.enable(true, ...)` on BufEnter,
	-- CursorHold and InsertLeave, and registers those handlers from LspAttach —
	-- later than anything defined here, so they run after us and would always
	-- win. Deferring with `vim.schedule` lands our call after the event's whole
	-- autocmd chain has finished.
	vim.schedule(function()
		if not owners[bufnr] or not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end
		if vim.lsp.codelens.is_enabled({ bufnr = bufnr }) then
			was_enabled[bufnr] = true
			vim.lsp.codelens.enable(false, { bufnr = bufnr })
		end
	end)
end

--- Keeps code lens off in `bufnr` until every owner that suppressed it calls `restore`.
--- @param bufnr integer
--- @param owner any
function M.suppress(bufnr, owner)
	if not owners[bufnr] then
		owners[bufnr] = {}
		vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
			group = group,
			buffer = bufnr,
			callback = function()
				off(bufnr)
			end,
		})
	end
	owners[bufnr][owner] = true
	off(bufnr)
end

--- @param owner any
function M.restore(owner)
	for bufnr, held_by in pairs(owners) do
		held_by[owner] = nil
		if next(held_by) == nil then
			owners[bufnr] = nil
			if vim.api.nvim_buf_is_valid(bufnr) then
				vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
				if was_enabled[bufnr] then
					vim.lsp.codelens.enable(true, { bufnr = bufnr })
				end
			end
			was_enabled[bufnr] = nil
		end
	end
end

return M
