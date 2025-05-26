local colors = require("config.colors")

local theme = {
  normal = {
    a = { fg = colors.graydark },
    x = { fg = colors.graydark },
    y = { fg = colors.graydark },
    z = { fg = colors.graydark },
  },
  insert = { z = { fg = colors.magenta } },
  visual = { z = { fg = colors.orange } },
  command = { z = { fg = colors.red } },
  replace = { z = { fg = colors.red } },

  inactive = {
    a = { fg = colors.graydark, bg = colors.black },
    b = { fg = colors.white, bg = colors.black },
    c = { fg = colors.white, bg = colors.black },
  },
}

local mode_aliases = {
  NORMAL = "nrml",
  INSERT = "insr",
  VISUAL = "visl",
  COMMAND = "cmnd",
}

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      return {
        require("lualine").setup({
          options = {
            theme = theme,
            component_separators = "|",
            section_separators = { right = "", left = "" },
            always_divide_middle = true,
          },

          sections = {
            lualine_a = { "filename", { "location", padding = { left = 0 } } },
            lualine_b = {},
            lualine_c = {},
            lualine_x = {},
            lualine_y = { "branch", "diff" },
            lualine_z = {
              {
                "mode",
                fmt = function(str)
                  return mode_aliases[str]
                end,
                padding = { left = 1, right = 0 },
              },
            },
          },

          inactive_sections = {
            lualine_a = { "filename" },
            lualine_b = {},
            lualine_c = {},
            lualine_x = {},
            lualine_y = {},
            lualine_z = {},
          },
          tabline = {},
          extensions = {},
        }),
      }
    end,
  },
}
