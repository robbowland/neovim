return {
  {
    "mason-org/mason.nvim",
    optional = true,
    keys = function(_, keys)
      for _, key in ipairs(keys) do
        if key[1] == "<leader>gg" then
          key[1] = "<leader>gc"
          key.desc = "Git Commit (Root Dir)"
        elseif key[1] == "<leader>gG" then
          key[1] = "<leader>gC"
          key.desc = "Git Commit (cwd)"
        end
      end
      return keys
    end,
  },
}
