-- Snacks picker theming (standalone)
-- Base for normal; selection = microcontrast plate + bold + BRIGHT fg.
-- Icons: brighten DevIcon/MiniIcons on selection. Matches highlight = yellow.

local M = {}

-- state
local icon_override_applied = false
local icon_highlight_cache = {}
M._colors = {}

-- utils ----------------------------------------------------------------------

local function sanitize_highlight_name(name)
  return (name or "unknown"):gsub("[^%w_]", "_")
end

-- pick first present hex from palette keys (expects "#rrggbb")
local function pick(...)
  for i = 1, select("#", ...) do
    local k = select(i, ...)
    local v = k and M._colors[k]
    if type(v) == "string" and v:match("^#%x%x%x%x%x%x$") then
      return v
    end
  end
end

local function hex_to_rgb(hex)
  if type(hex) ~= "string" then
    return nil, nil, nil
  end

  local r, g, b = hex:match("^#?(%x%x)(%x%x)(%x%x)$")
  if not r then
    return nil, nil, nil
  end
  return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

local function rgb_to_hex(r, g, b)
  local function c(x)
    return math.max(0, math.min(255, x))
  end
  return string.format("#%02x%02x%02x", c(r), c(g), c(b))
end

local function brighten_hex(hex, pct)
  local r, g, b = hex_to_rgb(hex)
  if not r then
    return hex
  end
  local f = 1 + (pct or 0.15)
  return rgb_to_hex(math.floor(r * f), math.floor(g * f), math.floor(b * f))
end

local function hl_fg_hex(name, fallback_hex)
  local ok, base = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  local n = ok and base and base.fg or nil
  return (type(n) == "number") and string.format("#%06x", n) or fallback_hex
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
  vim.api.nvim_set_hl(0, derived, { fg = bright, bg = "NONE", bold = true })
  return derived
end

local function refresh_icon_highlights()
  for base_hl, derived in pairs(icon_highlight_cache) do
    local base_hex = hl_fg_hex(base_hl, pick("white_bright", "white") or "#ffffff")
    local bright = brighten_hex(base_hex, 0.15)
    vim.api.nvim_set_hl(0, derived, { fg = bright, bg = "NONE", bold = true })
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
      { win = "preview", title = "{preview}", width = 0.52, border = "left", title_pos = "center" },
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
      { box = "vertical", border = "none", height = 0.45, { win = "list", border = "none" } },
      { win = "preview", title = "{preview}", border = "top", height = 0.55, title_pos = "center" },
    },
  }
end

local function configure_layout(picker_opts)
  picker_opts.prompt = picker_opts.prompt or "❯ "
  picker_opts.layout = function()
    return (vim.o.columns >= 140) and horizontal_layout() or vertical_layout()
  end
end

-- windows & formatting --------------------------------------------------------

local function configure_windows(picker_opts)
  picker_opts.win = picker_opts.win or {}
  picker_opts.win.input = vim.tbl_deep_extend("force", picker_opts.win.input or {}, {
    wo = { winhighlight = "Normal:SnacksPickerNormal,FloatBorder:SnacksPickerBorder" },
  })
  picker_opts.win.list = vim.tbl_deep_extend("force", picker_opts.win.list or {}, {
    wo = { winhighlight = "Normal:SnacksPickerNormal,FloatBorder:SnacksPickerBorder,CursorLine:SnacksPickerSelection" },
  })
  picker_opts.win.preview = vim.tbl_deep_extend("force", picker_opts.win.preview or {}, {
    wo = { winhighlight = "Normal:SnacksPickerNormal,FloatBorder:SnacksPickerBorder" },
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
  local fmt = require("snacks.picker.format")
  local orig = fmt.filename

  fmt.filename = function(item, picker)
    local ret = orig(item, picker)
    local list = picker and picker.list
    if not (list and list.cursor) then
      return ret
    end
    local current = list:get(list.cursor)
    if not current then
      return ret
    end
    if list:select_key(current) ~= list:select_key(item) then
      return ret
    end

    for _, chunk in ipairs(ret) do
      local hlname = chunk and chunk[2]
      if type(hlname) == "string" and (hlname:match("^DevIcon") or hlname:match("^MiniIcons")) then
        chunk[2] = create_icon_highlight(hlname)
        break
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
  local fg_base = pick("white", "gray") or "#e6edf3"
  local fg_dir_base = pick("blue") or "#58a6ff"
  local fg_file_sel = pick("white_bright", "white") or "#ffffff"
  local fg_dir_sel = pick("blue_bright", "cyan", "blue") or "#a5d6ff"
  local border_fg = pick("white", "gray_bright", "white_dim") or "#6e7681"
  local bg_normal = pick("surface_0", "black") or "#161b22"
  local bg_selection = pick("surface_1", "gray_dim") or "#21262d"

  -- windows
  vim.api.nvim_set_hl(0, "SnacksPickerNormal", { fg = fg_base, bg = bg_normal })

  -- rows
  vim.api.nvim_set_hl(0, "SnacksPickerFile", { fg = fg_base, bg = "NONE" })
  vim.api.nvim_set_hl(0, "SnacksPickerDirectory", { fg = fg_dir_base, bg = "NONE" })
  vim.api.nvim_set_hl(0, "SnacksPickerDir", { fg = fg_dir_base, bg = "NONE" })

  local sel = { bg = bg_selection, bold = true, italic = false }
  vim.api.nvim_set_hl(0, "SnacksPickerSelection", sel)
  vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", sel)
  vim.api.nvim_set_hl(0, "SnacksPickerSelected", sel)
  vim.api.nvim_set_hl(0, "SnacksPickerFileSelected", { fg = fg_file_sel, bg = bg_selection, bold = true })
  vim.api.nvim_set_hl(0, "SnacksPickerDirectorySelected", { fg = fg_dir_sel, bg = bg_selection, bold = true })
  vim.api.nvim_set_hl(0, "SnacksPickerDirSelected", { fg = fg_dir_sel, bg = bg_selection, bold = true })

  -- chrome
  vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = border_fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "SnacksPickerPrompt", { fg = pick("magenta", "cyan") or "#bc8cff", bold = true })
  vim.api.nvim_set_hl(0, "SnacksPickerTitle", { fg = pick("blue", "cyan") or "#58a6ff", bold = true })

  -- match highlight (yellow for fuzzy matches)
  local yellow = pick("yellow") or "#d29922"
  local yellow_brt = pick("yellow_bright", "yellow") or "#e3b341"
  vim.api.nvim_set_hl(0, "SnacksPickerMatch", { fg = yellow, bg = "NONE", bold = false })
  vim.api.nvim_set_hl(0, "SnacksPickerMatchSelected", { fg = yellow_brt, bg = bg_selection, bold = true })

  refresh_icon_highlights()
end

local function setup_picker_highlights(colors)
  M._colors = colors or {}
  apply_picker_theme()
  local group = vim.api.nvim_create_augroup("SnacksPickerThemeConfig", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = apply_picker_theme,
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
