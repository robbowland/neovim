return {
  "folke/noice.nvim",
  opts = {
    views = {
      cmdline_popup = {
        position = {
          row = "50%",
          col = "50%",
        },
        size = {
          width = 60,
          height = "auto",
        },
        border = {
          style = "rounded",
          padding = { 0, 1 },
        },
        win_options = {
          winhighlight = {
            Normal = "NormalFloat",
            FloatBorder = "NoiceCmdlinePopupBorder",
          },
        },
      },
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
