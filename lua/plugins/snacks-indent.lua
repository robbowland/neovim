return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    -- Set plugin-specific colours
    local function set_context_theme()
      vim.api.nvim_set_hl(0, "SnacksIndent", { fg = "#141414" })
      vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = "#5e5e5e" })
    end
    -- Reapply after color scheme cahnges
    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = set_context_theme,
    })
    set_context_theme()
  end,
}
