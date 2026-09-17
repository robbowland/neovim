local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(source))
local spec = dofile(root .. "/lua/plugins/lsp-python.lua")
local checks = 0

local function expect(condition, message)
  checks = checks + 1
  assert(condition, message)
end

local function executable(path)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile({ "#!/bin/sh" }, path)
  vim.uv.fs_chmod(path, 493)
end

local opts = { servers = {} }
spec[1].opts(nil, opts)

local before_init = opts.servers.basedpyright.before_init
local basedpyright_command = opts.servers.basedpyright.cmd
local ruff_command = opts.servers.ruff.cmd
expect(type(before_init) == "function", "BasedPyright should configure the project interpreter")
expect(type(basedpyright_command) == "function", "BasedPyright should resolve its project command at startup")
expect(type(ruff_command) == "function", "Ruff should resolve its project command at startup")

local project_root = vim.fn.tempname()
local venv_bin = project_root .. "/.venv/bin"
local python = venv_bin .. "/python"
local basedpyright = venv_bin .. "/basedpyright-langserver"
local ruff = venv_bin .. "/ruff"
executable(python)
executable(basedpyright)
executable(ruff)

local project_config = {
  root_dir = project_root,
  settings = { basedpyright = { disableOrganizeImports = true } },
}
before_init({}, project_config)
expect(project_config.settings.python.pythonPath == python, "BasedPyright should use the project virtual environment")
expect(
  project_config.settings.basedpyright.disableOrganizeImports == true,
  "configuring the interpreter should preserve BasedPyright settings"
)

local original_start = vim.lsp.rpc.start
local commands = {}
vim.lsp.rpc.start = function(command)
  table.insert(commands, command)
  return {}
end
basedpyright_command({}, project_config)
ruff_command({}, project_config)
basedpyright_command({}, { root_dir = project_root .. "/missing" })
vim.lsp.rpc.start = original_start

expect(vim.deep_equal(commands[1], { basedpyright, "--stdio" }), "BasedPyright should use the project-local executable")
expect(vim.deep_equal(commands[2], { ruff, "server" }), "Ruff should use the project-local executable")
expect(
  vim.deep_equal(commands[3], { "basedpyright-langserver", "--stdio" }),
  "BasedPyright should retain the Mason fallback when no project executable exists"
)

vim.fn.delete(project_root, "rf")
print(("lsp-python: %d checks passed"):format(checks))
