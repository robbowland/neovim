local colors = require("config.colors")
local diffview = require("config.diffview")

local theme = {
  normal = {
    a = { fg = colors.gray_dim },
    x = { fg = colors.gray_dim },
    y = { fg = colors.gray_dim },
    z = { fg = colors.gray_dim },
  },
  insert = { z = { fg = colors.magenta } },
  visual = { z = { fg = colors.orange } },
  command = { z = { fg = colors.red } },
  replace = { z = { fg = colors.red } },

  inactive = {
    a = { fg = colors.gray_dim, bg = colors.black },
    b = { fg = colors.white, bg = colors.black },
    c = { fg = colors.white, bg = colors.black },
  },
}

-- In an nvim weaver opened for an agent: the agent's state wherever weaver's
-- own bar (a winbar on file windows) is not shown, such as in a review.
local function agent()
  local status = package.loaded["weaver.status"]
  return status and status.statusline and status.statusline() or ""
end

local mode_aliases = {
  NORMAL = "nrml",
  INSERT = "insr",
  VISUAL = "visl",
  COMMAND = "cmnd",
}

local function has_no_diffview_file()
  return not diffview.has_statusline_file()
end

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
            lualine_a = {
              {
                diffview.statusline_file_summary,
                cond = diffview.has_statusline_file,
              },
              {
                "filename",
                cond = has_no_diffview_file,
              },
              { "location", padding = { left = 0 } },
            },
            lualine_b = {},
            lualine_c = {},
            lualine_x = {
              {
                agent,
                cond = function()
                  return agent() ~= ""
                end,
              },
            },
            lualine_y = {
              {
                diffview.statusline,
                cond = diffview.has_statusline_context,
              },
              {
                -- A code token, [ GIT: main ], not a Nerd Font branch icon.
                "branch",
                icon = "",
                fmt = diffview.git_token,
                cond = function()
                  return not diffview.has_statusline_context()
                end,
              },
              {
                "diff",
                cond = has_no_diffview_file,
              },
            },
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
            lualine_a = {
              {
                diffview.statusline_file_summary,
                cond = diffview.has_statusline_file,
              },
              {
                "filename",
                cond = has_no_diffview_file,
              },
            },
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
