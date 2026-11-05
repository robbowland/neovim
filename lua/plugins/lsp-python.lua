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

local function git_lines(dir, arguments)
  local result = vim.system(vim.list_extend({ "git", "-C", dir }, arguments), { text = true }):wait()
  if result.code ~= 0 then
    return nil
  end
  return vim.split(vim.trim(result.stdout), "\n", { plain = true })
end

-- The same directory in the repository's main checkout, when root_dir is in a
-- linked worktree.
local function main_checkout_dir(root_dir)
  local toplevel = git_lines(root_dir, { "rev-parse", "--show-toplevel" })
  local worktrees = git_lines(root_dir, { "worktree", "list", "--porcelain" })
  local main = worktrees and worktrees[1]:match("^worktree (.+)$")
  if not (toplevel and main) or main == toplevel[1] then
    return nil
  end

  local relative = vim.fs.relpath(toplevel[1], vim.uv.fs_realpath(root_dir) or root_dir)
  if relative == nil then
    return nil
  end
  return relative == "." and main or vim.fs.joinpath(main, relative)
end

local function venv_executable(dir, name)
  local executable = vim.fs.joinpath(dir, ".venv", "bin", name)
  if vim.fn.executable(executable) == 1 then
    return executable
  end
end

-- Worktrees from weaver and agents have no .venv until something runs uv
-- there, so the main checkout's environment stands in: without one,
-- BasedPyright analyses against Mason's Python and every third-party import
-- is unresolved. A running server keeps the environment it started with;
-- :LspRestart after the worktree gets its own.
local function project_venv_executable(root_dir, name)
  if root_dir == nil then
    return nil
  end

  local executable = venv_executable(root_dir, name)
  if executable then
    return executable
  end

  local main_dir = main_checkout_dir(root_dir)
  return main_dir and venv_executable(main_dir, name)
end

local function configure_project_python(_, config)
  local python_path = project_venv_executable(config.root_dir, "python")
  if python_path == nil then
    return
  end

  config.settings = config.settings or {}
  config.settings.python = config.settings.python or {}
  config.settings.python.pythonPath = config.settings.python.pythonPath or python_path
end

local function project_command(name, arguments)
  return function(dispatchers, config)
    local command = project_venv_executable(config.root_dir, name) or name
    return vim.lsp.rpc.start(vim.list_extend({ command }, arguments), dispatchers, {
      cwd = config.cmd_cwd,
      env = config.cmd_env,
      detached = config.detached,
    })
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
        before_init = configure_project_python,
        cmd = project_command("basedpyright-langserver", { "--stdio" }),
        cmd_env = {
          -- Pyright only empties its caches near the heap limit, so a lower limit stops each
          -- worktree's server growing for days. Raise it if hovers start re-analysing constantly.
          NODE_OPTIONS = "--max-old-space-size=1536",
        },
        settings = {
          basedpyright = {
            disableOrganizeImports = true, -- Ruff handles import organization.
          },
        },
      })
      opts.servers.ruff = vim.tbl_deep_extend("force", opts.servers.ruff or {}, server_options, {
        enabled = true,
        cmd = project_command("ruff", { "server" }),
      })
    end,
  },
}
