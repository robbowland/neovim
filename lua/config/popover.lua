-- Popovers: a float centred over the editor, framed like the pickers and as
-- tall as yazi.nvim's, for the file trees on <leader>ft (snacks' explorer, and
-- Diffview's file panel during a review). Sized when opened.
local M = {}

local height_ratio = 0.9 -- yazi.nvim's floating_window_scaling_factor
local width_ratio = 0.4
local min_width = 50

function M.border()
  return vim.g.colors_name == "micrographics" and "single" or "rounded"
end

-- The popover's width: the usual one, or WANT when its content needs more,
-- within the editor.
function M.width(want)
  local usual = math.max(min_width, math.floor(vim.o.columns * width_ratio))
  return math.min(math.max(usual, want or 0), vim.o.columns - 4)
end

function M.height()
  return math.floor((vim.o.lines - vim.o.cmdheight) * height_ratio)
end

-- nvim_open_win() geometry for a popover WIDTH columns wide; the border
-- adds a cell on each side.
function M.float(width)
  local height = M.height()
  return {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - vim.o.cmdheight - height - 2) / 2),
    col = math.floor((vim.o.columns - width - 2) / 2),
    border = M.border(),
    zindex = 50,
  }
end

-- A snacks picker layout (the explorer's): search above the list, no preview.
function M.snacks_layout()
  return {
    preview = false,
    layout = {
      backdrop = false,
      box = "vertical",
      width = M.width(),
      height = M.height(),
      border = M.border(),
      title = "{title} {live} {flags}",
      title_pos = "center",
      { win = "input", height = 1, border = "bottom" },
      { win = "list", border = "none" },
    },
  }
end

return M
