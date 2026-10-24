-- Several worktrees run their own server at once, so keep each one's ceiling modest.
-- Raise this if tsserver starts crashing with out-of-memory errors.
local tsserver_memory = 3072

local tsserver_settings = {
  tsserver = {
    -- Use one tsserver process for syntax and semantic operations
    useSyntaxServer = "never",
    -- Cap tsserver's heap
    maxTsServerMemory = tsserver_memory,
  },
}

return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      vtsls = {
        cmd_env = {
          -- Cap the language server's heap to match tsserver
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
