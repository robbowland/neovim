local M = {}

M.dark = {
  paper = "#000000",
  ink = "#ffffff",
  metadata = "#999999",
  faint = "#404040",
  danger = "#ff3b2f",
}

M.light = {
  paper = "#ffffff",
  ink = "#000000",
  metadata = "#666666",
  faint = "#bfbfbf",
  danger = "#c81e1e",
}

function M.get(background)
  local variant = background == "light" and M.light or M.dark
  return vim.deepcopy(variant)
end

return M
