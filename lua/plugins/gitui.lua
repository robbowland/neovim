return {
  "mason-org/mason.nvim",
  opts = { ensure_installed = {} },

  init = function()
    local gitui = "/opt/homebrew/bin/gitui"
    if vim.fn.executable(gitui) ~= 1 then
      gitui = "gitui" -- fallback
    end

    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyVimKeymaps",
      once = true,
      callback = function()
        -- <leader>gc = Git Commit (Root Dir)
        vim.keymap.set("n", "<leader>gc", function()
          Snacks.terminal({ gitui }, { cwd = LazyVim.root.get() })
        end, { desc = "Git Commit (Root Dir)" })

        -- <leader>gC = Git Commit (cwd)
        vim.keymap.set("n", "<leader>gC", function()
          Snacks.terminal({ gitui })
        end, { desc = "Git Commit (cwd)" })
      end,
    })
  end,
}
