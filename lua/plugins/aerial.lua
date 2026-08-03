return {
  "stevearc/aerial.nvim",
  keys = {
    {
      "<leader>ss",
      function()
        require("aerial").snacks_picker()
      end,
      desc = "Symbols",
    },
  },
}
