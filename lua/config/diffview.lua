local M = {}

local uv = vim.uv

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

function M.refresh_statusline()
  if package.loaded.lualine then
    pcall(require("lualine").refresh, { place = { "statusline" } })
    return
  end

  vim.cmd.redrawstatus()
end

-- The pull request is stored with the branch it was looked up for, as
-- vim.t.diffview_pr = { branch, number }: weaver can adopt a view's tab and
-- relabel it, and the number must not follow.
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

      vim.t[tabpage].diffview_pr = { branch = branch, number = number }
      M.refresh_statusline()
    end)
  end)
end

-- weaver's one-view review (lua/plugins/weaver.lua), when weaver is
-- installed: a mapping pressed again brings its view back, or closes it from
-- inside, and another mapping replaces it rather than opening a second tab.
local function single_view()
  local ok, module = pcall(require, "weaver.diffview")
  return ok and module or nil
end

-- The repository a mapping acts on: the open review's while you are in it.
local function review_root(single)
  local view = single and single.current()
  if view and view.tabpage == vim.api.nvim_get_current_tabpage() then
    return single.root_here()
  end
  return git_root()
end

-- These views are labelled with their branch, the label add_pr_number checks
-- the tab still shows.
local function show(single, spec)
  local view = single.show(spec)
  if view then
    M.refresh_statusline()
    add_pr_number(spec.root, spec.label, view.tabpage)
  end
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
  vim.t[view.tabpage].diffview_pr = nil
  M.refresh_statusline()
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

function M.open_working_tree()
  local single = single_view()
  if not single then
    vim.cmd("DiffviewOpen")
    return
  end
  local root = review_root(single)
  if not root then
    return
  end
  local branch = current_branch(root)

  show(single, { key = "working tree", label = branch, root = root, compare = { kind = "index" } })
end

function M.open_all_changes()
  local single = single_view()
  local root = review_root(single)
  if not root then
    return
  end
  local branch = current_branch(root)

  if not single then
    open("DiffviewOpen", { ("origin/HEAD...%s"):format(branch), "--imply-local" }, root, branch)
    return
  end
  local base = single.default_base(root)
  if not base then
    notify("No base branch: no upstream or origin default branch, main or master", vim.log.levels.ERROR)
    return
  end
  show(single, { key = "branch", label = branch, root = root, compare = { kind = "branch", base = base } })
end

function M.open_all_changes_history()
  local single = single_view()
  local root = git_root()
  if not root then
    return
  end
  local branch = current_branch(root)
  local base = single and single.default_base(root) or "origin/HEAD"

  open("DiffviewFileHistory", { ("--range=%s..%s"):format(base, branch), "--base=LOCAL" }, root, branch)
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
    local single = single_view()
    if single then
      show(single, { key = "pull request", label = branch, root = root, compare = { kind = "branch", base = base } })
      return
    end
    open("DiffviewOpen", { ("%s...HEAD"):format(base), "--imply-local" }, root, branch)
  end)
end

-- Close the Diffview in this tab. With weaver, once the view has finished
-- opening its file (closing earlier raises errors inside Diffview), and from
-- the tab you came from (closing the current tab fails while noice has a
-- float in it).
function M.close()
  local single = single_view()
  if single then
    single.close()
    return
  end
  vim.cmd("DiffviewClose")
end

-- gf in a review: the file at the same line, in the tab whose working
-- directory holds it (its worktree's tab), not just the previous tab.
function M.goto_file()
  local single = single_view()
  if single then
    single.goto_file()
    return
  end
  require("diffview.actions").goto_file_edit()
end

-- The review's branch and pull request as Micrographics code tokens, like the
-- vault's [ LNK: title ]: [ GIT: main ]  [ PR: #475 ].
function M.git_token(branch)
  return (branch or "") ~= "" and ("[ GIT: %s ]"):format(branch) or ""
end

local function is_statusline_file(file)
  return type(file) == "table" and type(file.path) == "string" and file.path ~= "" and file.path ~= "null"
end

-- The file under the panel's cursor, else (on a directory row) the file open
-- in the diff.
local function statusline_file()
  local lib = package.loaded["diffview.lib"]
  local view = lib and lib.get_current_view()
  if not view then
    return nil
  end

  local ok, file = pcall(view.infer_cur_file, view)
  if not (ok and is_statusline_file(file)) then
    file = view.panel.cur_file
  end
  return is_statusline_file(file) and file or nil
end

function M.statusline()
  local branch = vim.t.diffview_context or ""
  if branch == "" then
    return ""
  end
  local pr = vim.t.diffview_pr
  return M.git_token(branch) .. (pr and pr.branch == branch and ("  [ PR: #%s ]"):format(pr.number) or "")
end

function M.has_statusline_context()
  return M.statusline() ~= ""
end

function M.statusline_file_summary()
  local file = statusline_file()
  if not file then
    return ""
  end

  local additions = file.stats and file.stats.additions
  local deletions = file.stats and file.stats.deletions
  -- The file panel hides until wanted: say how to get it.
  local view = require("diffview.lib").get_current_view()
  local hint = ""
  if view and view.panel and not view.panel:is_open() then
    hint = "  · files: <leader>e, or the right edge"
  end

  if type(additions) == "number" and type(deletions) == "number" then
    return ("%s  +%d -%d%s"):format(file.path, additions, deletions, hint)
  end

  return file.path .. hint
end

function M.has_statusline_file()
  return M.statusline_file_summary() ~= ""
end

return M
