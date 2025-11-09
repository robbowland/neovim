local colors = require("config.colors")
local picker = require("config.snacks.picker")

return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    picker.setup(opts, colors)

    local function set_indent_theme()
      vim.api.nvim_set_hl(0, "SnacksIndent", { fg = colors.graydarker })
      vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = colors.graydark })
    end

    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = set_indent_theme,
    })
    set_indent_theme()
  end,
}
