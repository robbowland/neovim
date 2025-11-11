local colors = require("config.colors")

return {
  "nvim-treesitter/nvim-treesitter-context",
  opts = function(_, opts)
    -- Set plugin-specific colours
    local function set_context_theme()
      vim.api.nvim_set_hl(0, "TreesitterContext", { bg = colors.black })
      vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true, sp = colors.gray_dim })
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
