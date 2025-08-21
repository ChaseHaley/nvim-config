return {
  dir = vim.fn.stdpath("config") .. "/lua/regioner", -- local plugin
  name = "regioner",
  config = function()
    require("regioner").setup({
      -- Optional: offer a quick-pick like VS Code
      presets = {
        "Using Directives",
        "Private Data Members",
        "Constructors",
        "Internal Methods",
        "Public Methods",
        "Public Events",
        "Private Methods",
        "Private Event Handlers",
      },
      -- Optional: override comment leader per your stack
      -- comment_leader = "//",
      -- key_wrap = "<leader>r",
      -- key_pick = "<leader>R",
    })
  end,
}

