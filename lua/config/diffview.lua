local M = {}

local uv = vim.uv or vim.loop

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Diffview" })
end

local function command_error(result)
  local message = vim.trim(result.stderr or "")
  if message == "" then
    message = vim.trim(result.stdout or "")
  end
  return message ~= "" and message or ("command exited with status %d"):format(result.code)
end

local function run(cwd, args, callback)
  vim.system(args, { cwd = cwd, text = true }, function(result)
    vim.schedule(function()
      callback(result)
    end)
  end)
end

local function canonical_path(path)
  if not path or path == "" then
    return nil
  end

  path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  return uv.fs_realpath(path) or path
end

local function git_root()
  local candidates = {}
  local current_file = vim.api.nvim_buf_get_name(0)
  if current_file ~= "" then
    candidates[#candidates + 1] = vim.fs.dirname(current_file)
  end
  candidates[#candidates + 1] = vim.fn.getcwd()

  for _, cwd in ipairs(candidates) do
    local result = vim.system({ "git", "-C", cwd, "rev-parse", "--show-toplevel" }, { text = true }):wait()
    if result.code == 0 then
      return canonical_path(vim.trim(result.stdout or ""))
    end
  end

  notify("The current buffer is not in a Git repository", vim.log.levels.ERROR)
  return nil
end

local function current_branch(cwd)
  local result = vim.system({ "git", "symbolic-ref", "--quiet", "--short", "HEAD" }, { cwd = cwd, text = true }):wait()
  local branch = vim.trim(result.stdout or "")

  return result.code == 0 and branch ~= "" and branch or "HEAD"
end

local function refresh_statusline()
  if package.loaded.lualine then
    pcall(require("lualine").refresh, { place = { "statusline" } })
    return
  end

  vim.cmd.redrawstatus()
end

local function add_pr_number(cwd, branch, tabpage)
  if branch == "HEAD" or vim.fn.executable("gh") ~= 1 then
    return
  end

  vim.system({ "gh", "pr", "view", "--json", "number", "--jq", ".number" }, { cwd = cwd, text = true }, function(result)
    local number = vim.trim(result.stdout or "")
    if result.code ~= 0 or not number:match("^%d+$") then
      return
    end

    vim.schedule(function()
      if not vim.api.nvim_tabpage_is_valid(tabpage) or vim.t[tabpage].diffview_context ~= branch then
        return
      end

      vim.t[tabpage].diffview_context = ("%s  PR #%s"):format(branch, number)
      refresh_statusline()
    end)
  end)
end

local function open(command, args, cwd, branch)
  table.insert(args, 1, "-C" .. vim.fn.fnameescape(cwd))
  local ok, err = pcall(vim.cmd[command], { args = args })
  if not ok then
    notify("Could not open Diffview: " .. err, vim.log.levels.ERROR)
    return
  end

  local view = require("diffview.lib").get_current_view()
  if not view then
    return
  end

  vim.t[view.tabpage].diffview_context = branch
  refresh_statusline()
  add_pr_number(cwd, branch, view.tabpage)
end

local function ensure_gh()
  if vim.fn.executable("gh") == 1 then
    return true
  end

  notify("GitHub CLI is required", vim.log.levels.ERROR)
  return false
end

local function resolve_pr_base(root, callback)
  run(root, { "gh", "pr", "view", "--json", "baseRefName,baseRefOid" }, function(result)
    if result.code ~= 0 then
      notify("Could not resolve the pull request base: " .. command_error(result), vim.log.levels.ERROR)
      return
    end

    local ok, details = pcall(vim.json.decode, result.stdout or "")
    if not ok or type(details) ~= "table" or type(details.baseRefOid) ~= "string" then
      notify("The pull request did not report a valid base commit", vim.log.levels.ERROR)
      return
    end

    run(root, { "git", "cat-file", "-e", details.baseRefOid .. "^{commit}" }, function(git_result)
      if git_result.code ~= 0 then
        local base = type(details.baseRefName) == "string" and details.baseRefName or details.baseRefOid
        notify(("Base %q is not available locally; fetch it first"):format(base), vim.log.levels.ERROR)
        return
      end
      callback(details.baseRefOid)
    end)
  end)
end

function M.open_all_changes()
  local root = git_root()
  if not root then
    return
  end
  local branch = current_branch(root)

  open("DiffviewOpen", { ("origin/HEAD...%s"):format(branch), "--imply-local" }, root, branch)
end

function M.open_all_changes_history()
  local root = git_root()
  if not root then
    return
  end
  local branch = current_branch(root)

  open("DiffviewFileHistory", { ("--range=origin/HEAD..%s"):format(branch), "--base=LOCAL" }, root, branch)
end

function M.open_current_pr_diff()
  if not ensure_gh() then
    return
  end
  local root = git_root()
  if not root then
    return
  end
  local branch = current_branch(root)

  resolve_pr_base(root, function(base)
    open("DiffviewOpen", { ("%s...HEAD"):format(base), "--imply-local" }, root, branch)
  end)
end

function M.statusline()
  return vim.t.diffview_context or ""
end

function M.has_statusline_context()
  return M.statusline() ~= ""
end

return M
