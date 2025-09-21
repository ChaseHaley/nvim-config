if vim.g.vscode then
	return {}
end

return {
	'seblyng/roslyn.nvim',
	-- ft = { 'cs', 'razor' },
	-- dependencies = {
	-- 	{
	-- 		-- By loading as a dependencies, we ensure that we are available to set
	-- 		-- the handlers for Roslyn.
	-- 		'tris203/rzls.nvim',
	-- 		config = true,
	-- 	},
	-- },
	config = function()
		---@module 'roslyn.config'
		---@type RoslynNvimConfig
		require('roslyn').setup({
			filewatching = 'roslyn',
		});

		vim.lsp.config('roslyn', {
			-- filewatching = 'roslyn',
			settings = {
				['csharp|background_analysis'] = {
					dotnet_analyzer_diagnostics_scope = 'openFiles',
					dotnet_compiler_diagnostics_scope = 'openFiles',
				},
			},
		})
		vim.lsp.enable 'roslyn'
	end,
	init = function()
		-- We add the Razor file types before the plugin loads.
		vim.filetype.add {
			extension = {
				razor = 'razor',
				cshtml = 'razor',
			},
		}
	end,
}
