local colors = require("config.colors")

return {
  {
    "projekt0n/github-nvim-theme",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
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
            CursorLine = { bg = colors.graydarkest },
          },
        },
      })

      vim.cmd("colorscheme github_dark_default")
    end,
  },
}
