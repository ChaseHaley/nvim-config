return {
	{
		'nvimtools/none-ls.nvim',
		event = 'VeryLazy',
		dependencies = { 'davidmh/cspell.nvim' },
		opts = function(_, opts)
			local cspell = require 'cspell'
			opts.sources = opts.sources or {}
			table.insert(
				opts.sources,
				cspell.diagnostics.with {
					diagnostics_postprocess = function(diagnostic)
						diagnostic.severity = vim.diagnostic.severity.HINT
					end,
					cspell_config_dirs = { 'C:/Dev/Extras/CSpell/', 'C:\\Dev\\Extras\\CSpell\\' },
				}
			)
			table.insert(
				opts.sources,
				cspell.code_actions.with {
					cspell_config_dirs = { 'C:/Dev/Extras/CSpell/', 'C:\\Dev\\Extras\\CSpell\\' },
				}
			)
		end,
	},
}
