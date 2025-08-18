if vim.g.vscode then
	return {}
end

return {
	{ -- You can easily change to a different colorscheme.
		-- Change the name of the colorscheme plugin below, and then
		-- change the command in the config to whatever the name of that colorscheme is.
		--
		-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
		'folke/tokyonight.nvim',
		priority = 1000, -- Make sure to load this before all the other start plugins.
		config = function()
			-- if Is_Windows() then
			if 1 == 1 then
				require('tokyonight').setup {
					styles = {
						comments = { italic = false }, -- Disable italics in comments
					},
				}
				vim.cmd.colorscheme 'tokyonight-night'
			else
				---@diagnostic disable-next-line: missing-fields
				require('tokyonight').setup {
					transparent = true,
					styles = {
						comments = { italic = false }, -- Disable italics in comments
						sidebars = 'transparent',
						floats = 'transparent',
					},
				}

				-- Load the colorscheme here.
				-- Like many other themes, this one has different styles, and you could load
				-- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
				vim.cmd.colorscheme 'tokyonight-night'

				-- Enable status line transparency (native nvim status line)
				vim.cmd [[
          hi StatusLine guibg=NONE ctermbg=NONE
          hi StatusLineNC guibg=NONE ctermbg=NONE
          hi StatusLineTerm guibg=NONE ctermbg=NONE
          hi StatusLineTermNC guibg=NONE ctermbg=NONE
        ]]

				-- Enable status line transparency (mini status line)
				for _, group in ipairs {
					'MiniStatuslineModeNormal',
					'MiniStatuslineModeInsert',
					'MiniStatuslineModeVisual',
					'MiniStatuslineModeReplace',
					'MiniStatuslineModeCommand',
					'MiniStatuslineModeOther',
					'MiniStatuslineFilename',
					'MiniStatuslineDevinfo',
					'MiniStatuslineFileinfo',
					'MiniStatuslineInactive',
				} do
					vim.cmd(('hi %s guibg=NONE ctermbg=NONE'):format(group))
				end

				-- Update mode text colors
				vim.api.nvim_create_autocmd('ColorScheme', {
					callback = function()
						local tgc = vim.opt.termguicolors:get()

						local gui = {
							normal = '#c0caf5', -- tweak to taste
							insert = '#7aa2f7',
							visual = '#bb9af7',
							replace = '#f7768e',
							command = '#e0af68',
							other = '#7dcfff',
						}
						local cterm = { normal = 15, insert = 39, visual = 141, replace = 203, command = 179, other = 44 }

						local function set(group, hex, idx)
							vim.cmd('hi! clear ' .. group) -- break links + attrs
							if tgc then
								vim.api.nvim_set_hl(0, group, { fg = hex, bg = 'NONE', bold = true, reverse = false, nocombine = true })
							else
								vim.cmd(('hi %s ctermfg=%d ctermbg=NONE cterm=bold'):format(group, idx))
							end
						end

						set('MiniStatuslineModeNormal', gui.normal, cterm.normal)
						set('MiniStatuslineModeInsert', gui.insert, cterm.insert)
						set('MiniStatuslineModeVisual', gui.visual, cterm.visual)
						set('MiniStatuslineModeReplace', gui.replace, cterm.replace)
						set('MiniStatuslineModeCommand', gui.command, cterm.command)
						set('MiniStatuslineModeOther', gui.other, cterm.other)

						-- keep the bar transparent and remove any lingering reverse
						vim.cmd [[hi! StatusLine gui=NONE cterm=NONE guibg=NONE ctermbg=NONE]]
						vim.cmd [[hi! StatusLineNC gui=NONE cterm=NONE guibg=NONE ctermbg=NONE]]
					end,
				})

				-- apply immediately on startup
				vim.cmd 'doautocmd ColorScheme'
			end
		end,
	},
}
-- vim: ts=2 sts=2 sw=2 et
