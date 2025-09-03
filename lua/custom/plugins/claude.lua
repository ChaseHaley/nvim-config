if Is_Windows() then
	return {}
end

return {
	'greggh/claude-code.nvim',
	dependencies = {
		'nvim-lua/plenary.nvim', -- Required for git operations
	},
	config = function()
		require('claude-code').setup()
	end,
}
