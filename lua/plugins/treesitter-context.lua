return {
  "nvim-treesitter/nvim-treesitter-context",
  opts = function(_, opts)
    -- Set plugin-specific colours
    local function set_context_theme()
      vim.api.nvim_set_hl(0, "TreesitterContext", { bg = "#000000" })
      vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true, sp = "#4b4b4b" })
      vim.api.nvim_set_hl(0, "TreesitterContextLineNumberBottom", { underline = true, sp = "#4b4b4b" })
    end
    -- Reapply after color scheme cahnges
    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = set_context_theme,
    })
    set_context_theme()

    return { max_lines = 20 }
  end,
}
