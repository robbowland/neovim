return {
  "nvim-neotest/neotest",
  dependencies = {
    "haydenmeade/neotest-jest",
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-jest")({
          jestCommand = "npx jest --",
          env = { CI = true },
          cwd = function()
            return vim.fn.getcwd()
          end,
        }),
      },
    })
  end,
}
