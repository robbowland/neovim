local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(source))
vim.opt.runtimepath:prepend(root)

local project_tools = require("config.project-tools")
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

local function project()
  local path = vim.fn.tempname()
  vim.fn.mkdir(path .. "/.git", "p")
  return path
end

local sibling_root = project()
local sibling_prettier = sibling_root .. "/frontend/node_modules/.bin/prettier"
local sibling_file = sibling_root .. "/sdk/react/src/client.ts"
executable(sibling_prettier)
vim.fn.mkdir(vim.fs.dirname(sibling_file), "p")
vim.fn.writefile({}, sibling_file)
expect(
  project_tools.node_executable(sibling_file, "prettier") == sibling_prettier,
  "a sole repository formatter should serve sibling packages"
)

local ancestor_root = project()
local ancestor_prettier = ancestor_root .. "/packages/app/node_modules/.bin/prettier"
local other_prettier = ancestor_root .. "/frontend/node_modules/.bin/prettier"
local ancestor_file = ancestor_root .. "/packages/app/src/client.ts"
executable(ancestor_prettier)
executable(other_prettier)
vim.fn.mkdir(vim.fs.dirname(ancestor_file), "p")
vim.fn.writefile({}, ancestor_file)
expect(
  project_tools.node_executable(ancestor_file, "prettier") == ancestor_prettier,
  "the nearest package formatter should win"
)

local ambiguous_root = project()
local ambiguous_file = ambiguous_root .. "/sdk/src/client.ts"
executable(ambiguous_root .. "/frontend/node_modules/.bin/prettier")
executable(ambiguous_root .. "/tools/node_modules/.bin/prettier")
vim.fn.mkdir(vim.fs.dirname(ambiguous_file), "p")
vim.fn.writefile({}, ambiguous_file)
expect(
  project_tools.node_executable(ambiguous_file, "prettier") == nil,
  "ambiguous sibling formatters should fall back instead of guessing"
)

vim.fn.delete(sibling_root, "rf")
vim.fn.delete(ancestor_root, "rf")
vim.fn.delete(ambiguous_root, "rf")
print(("project-tools: %d checks passed"):format(checks))
