return {
  "nvim-treesitter/nvim-treesitter-context",
  opts = function(_, opts)
    -- Define a function to set the underline highlight for the bottom border
    local function set_context_theme()
      vim.api.nvim_set_hl(0, "TreesitterContext", { bg = "#000000" })
      vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true, sp = "#4b4b4b" })
      vim.api.nvim_set_hl(0, "TreesitterContextLineNumberBottom", { underline = true, sp = "#4b4b4b" })
    end

    -- Apply the highlight settings
    set_context_theme()

    -- Reapply the highlight settings after colorscheme changes
    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = set_context_theme,
    })

    return { max_lines = 20 }
  end,
}
