local tsserver_memory = 6144

local tsserver_settings = {
  tsserver = {
    -- Disable the extra syntax server so we only spawn one tsserver process
    useSeparateSyntaxServer = false,
    -- Raise the memory ceiling to reduce out-of-memory crashes
    maxTsServerMemory = tsserver_memory,
  },
}

return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      vtsls = {
        cmd_env = {
          -- Allow the language server to allocate more memory in large workspaces
          NODE_OPTIONS = ("--max-old-space-size=%d"):format(tsserver_memory),
        },
        settings = {
          typescript = vim.tbl_deep_extend("force", vim.deepcopy(tsserver_settings), {
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              variableTypes = { enabled = true },
            },
          }),
          javascript = vim.deepcopy(tsserver_settings),
        },
      },
    },
  },
}
