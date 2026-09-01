local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(source))
local spec = dofile(root .. "/lua/plugins/lsp-python.lua")
local checks = 0

local function expect(condition, message)
  checks = checks + 1
  assert(condition, message)
end

local opts = { servers = {} }
spec[1].opts(nil, opts)

local before_init = opts.servers.basedpyright.before_init
expect(
  type(before_init) == "function",
  "BasedPyright should configure a monorepo SDK interpreter before initialization"
)

local project_root = vim.fn.tempname()
local sdk_python = project_root .. "/sdk/.venv/bin/python"
vim.fn.mkdir(vim.fs.dirname(sdk_python), "p")
vim.fn.writefile({ "#!/bin/sh" }, sdk_python)
vim.uv.fs_chmod(sdk_python, 493)

local monorepo_config = {
  root_dir = project_root,
  settings = { basedpyright = { disableOrganizeImports = true } },
}
before_init({}, monorepo_config)
expect(
  monorepo_config.settings.python.pythonPath == sdk_python,
  "repository-rooted Python buffers should use the SDK virtual environment"
)
expect(
  monorepo_config.settings.basedpyright.disableOrganizeImports == true,
  "configuring the interpreter should preserve BasedPyright settings"
)

local component_config = { root_dir = project_root .. "/sdk", settings = {} }
before_init({}, component_config)
expect(
  component_config.settings.python == nil,
  "component-rooted buffers should retain their project interpreter selection"
)

vim.fn.delete(project_root, "rf")
print(("lsp-python: %d checks passed"):format(checks))
