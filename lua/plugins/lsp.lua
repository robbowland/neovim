return {
  "neovim/nvim-lspconfig",
  -- Highlight overrides that persist across :colorscheme
  init = function()
    local colors = require("config.colors")

    local function set_context_theme()
      -- Customize inlay hints (Neovim 0.10+ highlight group)
      vim.api.nvim_set_hl(0, "LspInlayHint", { bg = colors.black, fg = colors.graydark })
    end

    -- Reapply after any colorscheme change
    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = set_context_theme,
    })
    set_context_theme()
  end,

  keys = {
    { "K", false, mode = "n" }, -- disable LazyVim's default hover on K
    {
      "<C-k>",
      function()
        vim.lsp.buf.hover()
      end,
      mode = "n",
      desc = "LSP Hover",
    },
  },
}
