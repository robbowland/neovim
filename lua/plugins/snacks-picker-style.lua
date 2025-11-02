return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.picker = opts.picker or {}

    opts.picker.prompt = opts.picker.prompt or "❯ "

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

    opts.picker.layout = function()
      return vim.o.columns >= 140 and horizontal_layout() or vertical_layout()
    end

    opts.picker.win = opts.picker.win or {}
    opts.picker.win.input = vim.tbl_deep_extend("force", opts.picker.win.input or {}, {
      wo = {
        winhighlight = "Normal:SnacksPickerNormal,FloatBorder:SnacksPickerBorder",
      },
    })
    opts.picker.win.list = vim.tbl_deep_extend("force", opts.picker.win.list or {}, {
      wo = {
        winhighlight = "Normal:SnacksPickerNormal,FloatBorder:SnacksPickerBorder,CursorLine:SnacksPickerSelection",
      },
    })
    opts.picker.win.preview = vim.tbl_deep_extend("force", opts.picker.win.preview or {}, {
      wo = {
        winhighlight = "Normal:SnacksPickerNormal,FloatBorder:SnacksPickerBorder",
      },
    })

    opts.picker.formatters = opts.picker.formatters or {}
    opts.picker.formatters.file = vim.tbl_deep_extend("force", opts.picker.formatters.file or {}, {
      filename_first = true,
      truncate = "left",
    })

    local colors = require("config.colors")

    local function apply_picker_theme()
      vim.api.nvim_set_hl(0, "SnacksPickerNormal", { fg = colors.white, bg = colors.graydarkest })
      vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = colors.white, bg = colors.graydarkest })
      vim.api.nvim_set_hl(0, "SnacksPickerPrompt", { fg = colors.magenta, bg = colors.graydarkest, bold = true })
      vim.api.nvim_set_hl(0, "SnacksPickerTitle", { fg = colors.blue, bg = colors.graydarkest, bold = true })
      vim.api.nvim_set_hl(0, "SnacksPickerSelection", { fg = colors.white, bg = colors.gray })
    end

    local group = vim.api.nvim_create_augroup("ConfigSnacksPickerTheme", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = group,
      callback = apply_picker_theme,
    })
    apply_picker_theme()
  end,
}
