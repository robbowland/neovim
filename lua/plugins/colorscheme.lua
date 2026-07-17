local colors = require("config.colors")

return {
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    priority = 1000,
    config = function()
      require("github-theme").setup({
        groups = {
          github_dark_default = {
            NotifyINFOBorder = { fg = colors.white },
            FloatTitle = { fg = colors.white },
            FloatBorder = { fg = colors.white },
            Normal = { bg = colors.black },
            NormalNC = { bg = colors.black },
            NormalSB = { bg = colors.black },
            NormalFloat = { bg = colors.black },
            StatusLine = { bg = colors.black },
            CursorLine = { bg = colors.surface_0 },
          },
        },
      })

      vim.cmd("colorscheme micrographics")
    end,
  },
}
