local M = {}

function M.apply_theme()
  vim.api.nvim_set_hl(0, "SnacksIndent", { fg = "#141414" })
  vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = "#5e5e5e" })
end

return M
