return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      vtsls = {
        cmd_env = {
          -- Allow the language server to allocate more memory in large workspaces
          NODE_OPTIONS = "--max-old-space-size=6144",
        },
        settings = {
          typescript = {
            tsserver = {
              -- Disable the extra syntax server so we only spawn one tsserver process
              useSeparateSyntaxServer = false,
              -- Raise the memory ceiling to reduce out-of-memory crashes
              maxTsServerMemory = 6144,
            },
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              variableTypes = { enabled = true },
            },
          },
          javascript = {
            tsserver = {
              useSeparateSyntaxServer = false,
              maxTsServerMemory = 6144,
            },
          },
        },
      },
    },
  },
}
