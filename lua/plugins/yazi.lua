return {
  "mikavilpas/yazi.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "Yazi" },
  keys = {
    { "<leader>fe", "<cmd>Yazi<CR>", desc = "File Explorer" },
  },
  opts = {
    previewer = {
      width = 120,
    },
  },
}
