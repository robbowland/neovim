local colors = require("config.colors")

return {
  "folke/noice.nvim",
  -- shift+enter while typing a command runs it, as enter does
  -- (lua/config/keymaps.lua): it is Claude Code's newline, and noice's
  -- redirect of the output into a pane was only ever hit by accident.
  keys = {
    { "<S-Enter>", false, mode = "c" },
  },
  opts = function(_, opts)
    -- Set plugin-specific colours
    local function set_context_theme()
      vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorder", { fg = colors.white })
      vim.api.nvim_set_hl(0, "NoiceCmdlineIconCmdline", { fg = colors.magenta })
    end
    -- Reapply after color scheme changes
    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = set_context_theme,
    })
    set_context_theme()

    return {
      views = {
        cmdline_popup = {
          position = {
            row = "40%",
            col = "50%",
          },
          size = {
            width = 60,
            height = "auto",
          },
        },
        popupmenu = {
          relative = "editor",
          position = {
            row = "56%",
            col = "50%",
          },
          size = {
            width = 60,
            height = 10,
          },
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          win_options = {
            winhighlight = {
              Normal = "Normal",
              FloatBorder = "FloatBorder",
            },
          },
        },
      },
      presets = {
        command_palette = false,
        lsp_doc_border = true,
      },
      cmdline = {
        format = {
          cmdline = {
            pattern = "^:",
            icon = "❯",
            lang = "vim",
          },
        },
      },
    }
  end,
}
