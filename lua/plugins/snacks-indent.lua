return {
  "folke/snacks.nvim",
  event = "VeryLazy",
  opts = {
    indent = {
      enabled = true,
      char = "│", -- Character for indent guides
      hl = "SnacksIndent", -- Highlight group for indent guides
    },
    scope = {
      enabled = true,
      char = "│", -- Character for scope guides
      hl = "SnacksIndentScope", -- Highlight group for current scope
    },
  },
  config = function(_, opts)
    require("snacks").setup(opts)
    vim.api.nvim_set_hl(0, "SnacksIndent", { fg = "#141414" })
    vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = "#5e5e5e" })
  end,
}
