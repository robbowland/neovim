return {
  "sindrets/diffview.nvim",
  cmd = {
    "DiffviewClose",
    "DiffviewFileHistory",
    "DiffviewFocusFiles",
    "DiffviewOpen",
    "DiffviewRefresh",
    "DiffviewToggleFiles",
  },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen HEAD<cr>", desc = "Git Diff (Working Tree)" },
    {
      "<leader>gD",
      "<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<cr>",
      desc = "Git Diff (Full Branch)",
    },
    { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
    { "<leader>gF", "<cmd>DiffviewFileHistory %<cr>", desc = "Git Current File History (Diffview)" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Git History (Diffview)" },
  },
}
