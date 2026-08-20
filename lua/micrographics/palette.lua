local M = {}

M.dark = {
  paper = "#000000",
  ink = "#ffffff",
  metadata = "#999999",
  faint = "#404040",
  success = "#39d97a",
  danger = "#ff3b2f",
}

M.light = {
  paper = "#ffffff",
  ink = "#000000",
  metadata = "#666666",
  faint = "#bfbfbf",
  success = "#39d97a",
  danger = "#c81e1e",
}

function M.get(background)
  local variant = background == "light" and M.light or M.dark
  return vim.deepcopy(variant)
end

return M
