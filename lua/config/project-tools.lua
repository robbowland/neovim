local M = {}

local ignored_directories = {
  [".git"] = true,
  [".terraform"] = true,
  [".venv"] = true,
  [".worktrees"] = true,
  ["build"] = true,
  ["dist"] = true,
  ["node_modules"] = true,
}

local function executable(path)
  return vim.fn.executable(path) == 1
end

local function ancestor_node_executable(start_dir, root, name)
  local dir = start_dir

  while dir ~= nil do
    local candidate = vim.fs.joinpath(dir, "node_modules", ".bin", name)
    if executable(candidate) then
      return candidate
    end
    if dir == root then
      break
    end

    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
end

local function collect_node_executables(dir, name, depth, matches)
  local candidate = vim.fs.joinpath(dir, "node_modules", ".bin", name)
  if executable(candidate) then
    table.insert(matches, candidate)
  end

  if depth == 0 or #matches > 1 then
    return
  end

  for child, kind in vim.fs.dir(dir) do
    if kind == "directory" and not ignored_directories[child] then
      collect_node_executables(vim.fs.joinpath(dir, child), name, depth - 1, matches)
      if #matches > 1 then
        return
      end
    end
  end
end

function M.node_executable(filename, name)
  local start_dir = vim.fs.dirname(vim.fs.normalize(filename))
  local root = vim.fs.root(start_dir, ".git")
  local ancestor = ancestor_node_executable(start_dir, root, name)
  if ancestor ~= nil then
    return ancestor
  end
  if root == nil then
    return nil
  end

  local matches = {}
  collect_node_executables(root, name, 3, matches)
  if #matches == 1 then
    return matches[1]
  end
end

return M
