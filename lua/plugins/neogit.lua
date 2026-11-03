require("loadout").add({ "https://github.com/NeogitOrg/neogit" })
require("neogit").setup(
	---@type NeogitConfig
	{
		graph_style = "unicode",
		disable_insert_on_commit = true,
		commit_editor = {
			kind = "split_below_all",
			show_staged_diff = false,
		},
		popup = {
			kind = "split",
			show_title = true
		}
	}
)

local working_tree = "(working tree)"

local function open_diffview(args)
	local view = require("diffview.lib").diffview_open(args)
	if view then
		view:open()
	end
end

require("neogit.popups.diff.actions").range = function(popup)
	local git = require("neogit.lib.git")
	local util = require("neogit.lib.util")
	local FuzzyFinderBuffer = require("neogit.buffers.fuzzy_finder")

	local first = {}
	local item = popup:get_env("item")
	local section = popup:get_env("section")
	if section and (section.name == "log" or section.name == "recent") and item and item.name then
		table.insert(first, item.name)
	end
	table.insert(first, git.branch.current() or "HEAD")

	local options = util.deduplicate(
		util.merge(first, git.branch.get_all_branches(false), git.tag.list(), git.refs.heads())
	)

	local from = FuzzyFinderBuffer.new(options):open_async({
		prompt_prefix = "Diff for range from",
		refocus_status = false,
	})
	if not from then
		return
	end

	local to = FuzzyFinderBuffer.new(util.merge({ working_tree }, options)):open_async({
		prompt_prefix = "Diff from " .. from .. " to",
		refocus_status = false,
	})
	if not to then
		return
	end

	local choices = { "&1. Range (a..b)", "&2. Symmetric Difference (a...b)", "&3. Cancel" }
	local choice = require("neogit.lib.input").get_choice("Select type", { values = choices, default = #choices })

	popup:close()
	if choice == "1" then
		open_diffview({ to == working_tree and from or from .. ".." .. to })
	elseif choice == "2" then
		open_diffview(to == working_tree and { from, "--merge-base" } or { from .. "..." .. to })
	end
end

vim.keymap.set("n", "<leader>gns", "<cmd>Neogit<cr>", { desc = "Show Neogit UI" })
vim.keymap.set("n", "<leader>gnc", "<cmd>Neogit commit<cr>", { desc = "Neogit commit" })
vim.keymap.set("n", "<leader>gnp", "<cmd>Neogit pull<cr>", { desc = "Neogit pull" })
vim.keymap.set("n", "<leader>gnP", "<cmd>Neogit push<cr>", { desc = "Neogit push" })
vim.keymap.set("n", "<leader>gnr", "<cmd>Neogit rebase<cr>", { desc = "Neogit rebase" })
