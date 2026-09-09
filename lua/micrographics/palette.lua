local M = {}

local function ink_at(opacity, light_paper)
  local channel = math.floor(255 * (light_paper and (1 - opacity) or opacity) + 0.5)
  return ("#%02x%02x%02x"):format(channel, channel, channel)
end

M.dark = {
  paper = "#000000",
  ink = "#ffffff",
  metadata = ink_at(0.6, false),
  faint = ink_at(0.38, false),
  success = "#39d97a",
  danger = "#ff3b2f",
  diff_add = "#102419",
  diff_change = "#1c1c1c",
  diff_delete = "#2a1514",
  diff_text = "#333333",
}

M.light = {
  paper = "#ffffff",
  ink = "#000000",
  metadata = ink_at(0.6, true),
  faint = ink_at(0.38, true),
  success = "#39d97a",
  danger = "#c81e1e",
  diff_add = "#e8f3ec",
  diff_change = "#eeeeee",
  diff_delete = "#f8e9e8",
  diff_text = "#d8d8d8",
}

function M.get(background)
  local variant = background == "light" and M.light or M.dark
  return vim.deepcopy(variant)
end

return M
