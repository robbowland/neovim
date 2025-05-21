return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    -- Set the background and foreground colors for inlay hints
    vim.api.nvim_set_hl(0, "LspInlayHint", { bg = "#000000", fg = "#4b4b4b" })
  end,
}
