local colors = require("config.colors")

return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    -- Set plugin-specific colours
    local function set_context_theme()
      vim.api.nvim_set_hl(0, "LspInlayHint", { bg = colors.black, fg = colors.graydark })
    end
    -- Reapply after color scheme cahnges
    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = set_context_theme,
    })
    set_context_theme()
  end,
}
