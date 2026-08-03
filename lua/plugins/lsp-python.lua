-- Python LSP configuration using Neovim 0.11+ native APIs through LazyVim.
--
-- Extending LazyVim's server options keeps other nvim-lspconfig specs
-- composable and lets Mason provision enabled servers automatically.

local python_root_markers = {
  { "pyproject.toml", "pyrightconfig.json", "ruff.toml", ".ruff.toml" },
  { "setup.py", "setup.cfg" },
}

local function resolve_python_root(bufnr, on_dir)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local marker_root = vim.fs.root(bufnr, python_root_markers)
  local git_root = vim.fs.root(bufnr, ".git")

  if marker_root ~= nil then
    on_dir(marker_root)
    return
  end

  if git_root ~= nil then
    on_dir(git_root)
    return
  end

  if path ~= "" then
    on_dir(vim.fs.dirname(path))
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.general = capabilities.general or {}
      capabilities.general.positionEncodings = { "utf-16" }

      local server_options = {
        capabilities = capabilities,
        filetypes = { "python" },
        root_dir = resolve_python_root,
      }

      opts.servers.pyright = vim.tbl_deep_extend("force", opts.servers.pyright or {}, { enabled = false })
      opts.servers.ty = vim.tbl_deep_extend("force", opts.servers.ty or {}, { enabled = false })
      opts.servers.basedpyright = vim.tbl_deep_extend("force", opts.servers.basedpyright or {}, server_options, {
        enabled = true,
        settings = {
          basedpyright = {
            disableOrganizeImports = true, -- Ruff handles import organization.
          },
        },
      })
      opts.servers.ruff = vim.tbl_deep_extend("force", opts.servers.ruff or {}, server_options, { enabled = true })
    end,
  },
}
