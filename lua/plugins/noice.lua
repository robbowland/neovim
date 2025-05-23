return {
  "folke/noice.nvim",
  opts = {
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
      command_palette = false, -- Disable to avoid conflicts centering
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
  },
  config = function(_, opts)
    require("noice").setup(opts)
    -- Set the border color to white
    vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorder", { fg = "#ffffff", bg = "NONE" })
    vim.api.nvim_set_hl(0, "NoiceCmdlineIconCmdline", { fg = "#d1a8fe", bg = "NONE" })
  end,
}
