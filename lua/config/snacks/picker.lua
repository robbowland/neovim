-- Snacks picker theming (standalone)
-- Normal = base colors; Selection = microcontrast plate + bold + BRIGHT fg.
-- Icons: auto-brighten DevIcon/MiniIcons on selection. Borders/chrome subdued.

local M = {}

-- state
local icon_override_applied = false
local icon_highlight_cache = {}
M._colors = {}

-- utils ----------------------------------------------------------------------

local function sanitize_highlight_name(name)
  return (name or "unknown"):gsub("[^%w_]", "_")
end

-- choose first present color key (supports old/new palette names)
local function pick(...)
  for i = 1, select("#", ...) do
    local k = select(i, ...)
    local v = k and M._colors[k] or nil
    if type(v) == "string" and v:match("^#%x%x%x%x%x%x$") then
      return v
    end
  end
  return nil
end

-- hex helpers (+brighten) — all string-based (“#rrggbb”)
local function hex_to_rgb(hex)
  if type(hex) ~= "string" then
    return
  end
  local r, g, b = hex:match("^#?(%x%x)(%x%x)(%x%x)$")
  if not r then
    return
  end
  return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

local function clamp(x)
  return math.max(0, math.min(255, x))
end

local function rgb_to_hex(r, g, b)
  return string.format("#%02x%02x%02x", clamp(r), clamp(g), clamp(b))
end

local function brighten_hex(hex, pct) -- ~0.10..0.20
  local r, g, b = hex_to_rgb(hex)
  if not r then
    return hex
  end
  local f = 1 + (pct or 0.15)
  return rgb_to_hex(math.floor(r * f), math.floor(g * f), math.floor(b * f))
end

-- pull fg from an existing hl group; return "#rrggbb" or fallback
local function hl_fg_hex(name, fallback_hex)
  local ok, base = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  local n = ok and base and base.fg or nil
  if type(n) == "number" then
    return string.format("#%06x", n)
  end
  return fallback_hex
end

-- icon highlight derivation ---------------------------------------------------

local function create_icon_highlight(base_hl)
  if not base_hl then
    return "SnacksPickerIconSelected"
  end
  local cached = icon_highlight_cache[base_hl]
  if cached then
    return cached
  end
  local derived = "SnacksPickerIconSelected_" .. sanitize_highlight_name(base_hl)
  icon_highlight_cache[base_hl] = derived

  local base_hex = hl_fg_hex(base_hl, pick("white_bright", "white") or "#ffffff")
  local bright = brighten_hex(base_hex, 0.15)

  vim.api.nvim_set_hl(0, derived, { fg = bright, bg = "NONE", bold = true, italic = false })
  return derived
end

local function refresh_icon_highlights()
  for base_hl, derived in pairs(icon_highlight_cache) do
    local base_hex = hl_fg_hex(base_hl, pick("white_bright", "white") or "#ffffff")
    local bright = brighten_hex(base_hex, 0.15)
    vim.api.nvim_set_hl(0, derived, { fg = bright, bg = "NONE", bold = true, italic = false })
  end
end

-- layouts --------------------------------------------------------------------

local function horizontal_layout()
  return {
    layout = {
      box = "horizontal",
      width = 0.88,
      min_width = 110,
      height = 0.88,
      min_height = 30,
      backdrop = false,
      border = "rounded",
      title = "{title} {live} {flags}",
      {
        box = "vertical",
        border = "none",
        width = 0.48,
        { win = "input", height = 1, border = "bottom" },
        { win = "list", border = "none" },
      },
      {
        win = "preview",
        title = "{preview}",
        width = 0.52,
        border = "left",
        title_pos = "center",
      },
    },
  }
end

local function vertical_layout()
  return {
    layout = {
      box = "vertical",
      width = 0.96,
      height = 0.94,
      min_width = 80,
      min_height = 24,
      border = "rounded",
      title = "{title} {live} {flags}",
      { win = "input", height = 1, border = "bottom" },
      {
        box = "vertical",
        border = "none",
        height = 0.45,
        { win = "list", border = "none" },
      },
      {
        win = "preview",
        title = "{preview}",
        border = "top",
        height = 0.55,
        title_pos = "center",
      },
    },
  }
end

local function configure_layout(picker_opts)
  picker_opts.prompt = picker_opts.prompt or "❯ "
  picker_opts.layout = function()
    return vim.o.columns >= 140 and horizontal_layout() or vertical_layout()
  end
end

-- windows & formatting --------------------------------------------------------

local function configure_windows(picker_opts)
  picker_opts.win = picker_opts.win or {}
  picker_opts.win.input = vim.tbl_deep_extend("force", picker_opts.win.input or {}, {
    wo = {
      winhighlight = "Normal:SnacksPickerNormal,FloatBorder:SnacksPickerBorder",
    },
  })
  picker_opts.win.list = vim.tbl_deep_extend("force", picker_opts.win.list or {}, {
    wo = {
      -- CursorLine maps to our selection plate+bold
      winhighlight = "Normal:SnacksPickerNormal,FloatBorder:SnacksPickerBorder,CursorLine:SnacksPickerSelection",
    },
  })
  picker_opts.win.preview = vim.tbl_deep_extend("force", picker_opts.win.preview or {}, {
    wo = {
      winhighlight = "Normal:SnacksPickerNormal,FloatBorder:SnacksPickerBorder",
    },
  })
end

local function configure_formatters(picker_opts)
  picker_opts.formatters = picker_opts.formatters or {}
  picker_opts.formatters.file = vim.tbl_deep_extend("force", picker_opts.formatters.file or {}, {
    filename_first = true,
    truncate = "left",
  })
end

-- icon chunk override for selected row ---------------------------------------

local function override_icon_highlight()
  if icon_override_applied then
    return
  end
  icon_override_applied = true
  local picker_format = require("snacks.picker.format")
  local orig_filename = picker_format.filename

  picker_format.filename = function(item, picker)
    local ret = orig_filename(item, picker)
    if picker and picker.list and picker.list.cursor then
      local list = picker.list
      local current = list:get(list.cursor)
      if current then
        local cur_key = list:select_key(current)
        local item_key = list:select_key(item)
        if cur_key == item_key then
          for _, chunk in ipairs(ret) do
            local hlname = chunk and chunk[2]
            if type(hlname) == "string" then
              if hlname:match("^DevIcon") or hlname:match("^MiniIcons") then
                chunk[2] = create_icon_highlight(hlname)
                break
              end
            end
          end
        end
      end
    end
    return ret
  end
end

-- live refresh on cursor move -------------------------------------------------

local function wrap_on_change(picker_opts)
  if picker_opts._snacks_on_change_wrapped then
    return
  end
  picker_opts._snacks_on_change_wrapped = true
  local user_on_change = picker_opts.on_change
  picker_opts.on_change = function(picker, item)
    if user_on_change then
      pcall(user_on_change, picker, item)
    end
    local list = picker and picker.list
    if not (list and list.win and list.win:valid()) then
      return
    end
    list.dirty = true
    list:update({ force = true })
  end
end

-- highlights ------------------------------------------------------------------

local function apply_picker_theme()
  -- normal = base; selection = plate+bold+bright
  local fg_base = pick("white", "gray") or "#e6edf3"
  local fg_dir_base = pick("cyan", "blue") or "#79c0ff"
  local fg_file_sel = pick("white_bright", "white") or "#ffffff"
  local fg_dir_sel = pick("cyan_bright", "cyan", "blue") or "#a5d6ff"

  local border_fg = pick("white", "gray_bright", "white_dim") or "#6e7781"
  local bg_normal = pick("surface_0", "black") or "#0a0a0a"
  local bg_selection = pick("surface_1", "gray_dark") or "#121212"

  -- window
  vim.api.nvim_set_hl(0, "SnacksPickerNormal", { fg = fg_base, bg = bg_normal })

  -- normal file/dir labels
  vim.api.nvim_set_hl(0, "SnacksPickerFile", { fg = fg_base, bg = "NONE" })
  vim.api.nvim_set_hl(0, "SnacksPickerDirectory", { fg = fg_dir_base, bg = "NONE" })
  vim.api.nvim_set_hl(0, "SnacksPickerDir", { fg = fg_dir_base, bg = "NONE" })

  -- selected file/dir (brighten on selection)
  vim.api.nvim_set_hl(0, "SnacksPickerFileSelected", { fg = fg_file_sel, bg = bg_selection, bold = true })
  vim.api.nvim_set_hl(0, "SnacksPickerDirectorySelected", { fg = fg_dir_sel, bg = bg_selection, bold = true })
  vim.api.nvim_set_hl(0, "SnacksPickerDirSelected", { fg = fg_dir_sel, bg = bg_selection, bold = true })

  -- chrome
  vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = border_fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "SnacksPickerPrompt", { fg = pick("magenta", "cyan") or "#bc8cff", bg = "NONE", bold = true })
  vim.api.nvim_set_hl(0, "SnacksPickerTitle", { fg = pick("blue", "cyan") or "#58a6ff", bg = "NONE", bold = true })

  -- row plate (fg handled by *Selected groups)
  local sel = { bg = bg_selection, bold = true, italic = false }
  vim.api.nvim_set_hl(0, "SnacksPickerSelection", sel)
  vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", sel)
  vim.api.nvim_set_hl(0, "SnacksPickerSelected", sel)

  refresh_icon_highlights()
end

local function setup_picker_highlights(colors)
  M._colors = colors or {}
  apply_picker_theme()
  local group = vim.api.nvim_create_augroup("SnacksPickerThemeConfig", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { -- single string event to placate LSP
    group = group,
    callback = function()
      apply_picker_theme()
    end,
  })
end

-- public API -----------------------------------------------------------------

function M.setup(opts, colors)
  opts = opts or {}
  opts.picker = opts.picker or {}
  M._colors = colors or {}

  configure_layout(opts.picker)
  configure_windows(opts.picker)
  configure_formatters(opts.picker)
  override_icon_highlight()
  wrap_on_change(opts.picker)
  setup_picker_highlights(M._colors)

  return opts
end

return M
