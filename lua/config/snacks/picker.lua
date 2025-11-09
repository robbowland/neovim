local M = {}

local icon_override_applied = false

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
      {
        win = "input",
        height = 1,
        border = "bottom",
      },
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

local function configure_windows(picker_opts)
  picker_opts.win = picker_opts.win or {}
  picker_opts.win.input = vim.tbl_deep_extend("force", picker_opts.win.input or {}, {
    wo = {
      winhighlight = "Normal:SnacksPickerNormal,FloatBorder:SnacksPickerBorder",
    },
  })
  picker_opts.win.list = vim.tbl_deep_extend("force", picker_opts.win.list or {}, {
    wo = {
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
            if chunk.virtual and type(chunk[2]) == "string" then
              if chunk[2]:match("^DevIcon") or chunk[2]:match("^MiniIcons") then
                chunk[2] = "SnacksPickerIconSelected"
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

local function apply_picker_theme(colors)
  vim.api.nvim_set_hl(0, "SnacksPickerNormal", { fg = colors.white, bg = colors.graydarkest })
  vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = colors.white, bg = colors.graydarkest })
  vim.api.nvim_set_hl(0, "SnacksPickerPrompt", { fg = colors.magenta, bg = colors.graydarkest, bold = true })
  vim.api.nvim_set_hl(0, "SnacksPickerTitle", { fg = colors.blue, bg = colors.graydarkest, bold = true })
  vim.api.nvim_set_hl(0, "SnacksPickerSelection", { fg = colors.black, bg = colors.white, bold = true })
  vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { fg = colors.black, bg = colors.white, bold = true })
  vim.api.nvim_set_hl(0, "SnacksPickerSelected", { fg = colors.black, bg = colors.white, bold = true })
  vim.api.nvim_set_hl(0, "SnacksPickerIconSelected", { fg = colors.black, bg = colors.white, bold = true })
end

local function setup_picker_highlights(colors)
  apply_picker_theme(colors)
  local group = vim.api.nvim_create_augroup("ConfigSnacksPickerTheme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      apply_picker_theme(colors)
    end,
  })
end

function M.setup(opts, colors)
  opts.picker = opts.picker or {}
  configure_layout(opts.picker)
  configure_windows(opts.picker)
  configure_formatters(opts.picker)
  override_icon_highlight()
  wrap_on_change(opts.picker)
  setup_picker_highlights(colors)
end

return M
