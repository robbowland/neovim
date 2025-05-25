return {
  {
    "projekt0n/github-nvim-theme",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require("github-theme").setup({
        groups = {
          github_dark_default = {
            NotifyINFOBorder = { fg = "#FFFFFF" },
            FloatTitle = { fg = "#FFFFFF" },
            FloatBorder = { fg = "#FFFFFF" },
            Normal = { bg = "#000000" },
            NormalNC = { bg = "#000000" },
            NormalSB = { bg = "#000000" },
            NormalFloat = { bg = "#000000" },
            StatusLine = { bg = "#000000" },
            CursorLine = { bg = "#0B0A0A" },
          },
        },
      })

      vim.cmd("colorscheme github_dark_default")
    end,
  },
}
