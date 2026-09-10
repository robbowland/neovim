local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(source))
local spec = dofile(root .. "/lua/plugins/diffview.lua")
local snacks_spec = dofile(root .. "/lua/plugins/snacks.lua")
local checks = 0

local function expect(condition, message)
  checks = checks + 1
  assert(condition, message)
end

local function expect_foreground(name, color)
  local actual = vim.api.nvim_get_hl(0, { name = name, link = false }).fg
  expect(actual == tonumber(color:sub(2), 16), name .. " should use " .. color)
end

local function expect_background_only(name, color)
  local actual = vim.api.nvim_get_hl(0, { name = name, link = false })
  expect(actual.bg == tonumber(color:sub(2), 16), name .. " should use background " .. color)
  expect(actual.fg == nil, name .. " should preserve syntax foregrounds")
  expect(actual.bold == nil, name .. " should preserve normal text weight")
end

local function expect_unstyled(name)
  local actual = vim.api.nvim_get_hl(0, { name = name, link = false })
  for _, attribute in ipairs({ "fg", "bg", "bold" }) do
    expect(actual[attribute] == nil, name .. " should not set " .. attribute)
  end
end

local function configured_mapping(lhs)
  for _, mapping in ipairs(spec.keys) do
    if mapping[1] == lhs then
      return mapping
    end
  end
end

local function expect_command_mapping(lhs, command, description)
  local configured = configured_mapping(lhs)
  expect(configured ~= nil, lhs .. " should be mapped")
  expect(configured[2] == "<cmd>" .. command .. "<cr>", lhs .. " should run " .. command)
  expect(configured.desc == description, lhs .. " should be described as " .. description)
end

local function expect_function_mapping(lhs, description)
  local configured = configured_mapping(lhs)
  expect(configured ~= nil, lhs .. " should be mapped")
  expect(type(configured[2]) == "function", lhs .. " should run a Lua function")
  expect(configured.desc == description, lhs .. " should be described as " .. description)
end

local function configured_diffview_mapping(options, section, lhs)
  for _, mapping in ipairs(options.keymaps[section]) do
    if mapping[2] == lhs then
      return mapping
    end
  end
end

local snacks_keys = snacks_spec.keys(nil, {
  { "<leader>gd", desc = "Git Diff (hunks)" },
  { "<leader>gD", desc = "Git Diff (origin)" },
  { "<leader>gs", desc = "Git Status" },
})
expect(#snacks_keys == 2, "Snacks should only add its explorer mapping")
expect(snacks_keys[1][1] == "<leader>gs", "Snacks should preserve unrelated Git mappings")
expect(snacks_keys[2][1] == "<leader>e", "Snacks should add the explorer mapping")

vim.wait(1_000, function()
  return vim.fn.exists(":DiffviewOpen") == 2
end)

expect(vim.fn.exists(":DiffviewOpen") == 2, ":DiffviewOpen should be registered")
expect(vim.fn.exists(":DiffviewFileHistory") == 2, ":DiffviewFileHistory should be registered")
expect(vim.fn.exists(":DiffviewPR") == 2, ":DiffviewPR should be registered")

local options = type(spec.opts) == "function" and spec.opts() or spec.opts
expect(options.enhanced_diff_hl == nil, "Diffview should not add body highlighting outside the gutter")

local hooks = options.hooks or {}
local diff_buf_read = hooks.diff_buf_read
local diff_buf_win_enter = hooks.diff_buf_win_enter
local view_enter = hooks.view_enter or function() end
local view_leave = hooks.view_leave or function() end
expect(type(diff_buf_read) == "function", "Diffview should tune large diff buffers")
expect(type(diff_buf_win_enter) == "function", "Diffview should configure diff windows")

local source_groups = { "DiffAdd", "DiffChange", "DiffDelete", "DiffText", "DiffTextAdd" }
local function expect_source_window(win)
  local statuscolumn = vim.wo[win].statuscolumn
  expect(statuscolumn:find("%C", 1, true) ~= nil, "the Diffview gutter should retain fold controls")
  expect(statuscolumn:find("%s", 1, true) == nil, "the Diffview gutter should omit unrelated signs")
  local _, virtual_guards = statuscolumn:gsub("v:virtnum == 0", "")
  expect(virtual_guards == 2, "markers and line numbers should both be hidden on virtual rows")

  local winhighlight = vim.wo[win].winhighlight
  for _, group in ipairs(source_groups) do
    local mapping = group .. ":MicrographicsDiffviewSource"
    local _, mappings = winhighlight:gsub(mapping, "")
    expect(mappings == 1, group .. " should map exactly once to the unstyled Diffview source group")
  end
end

vim.cmd("tabnew")
local old_win = vim.api.nvim_get_current_win()
local old_buf = vim.api.nvim_get_current_buf()
local old_lines = { "same", "old only", "shared", "changed old", "end" }
for line = 6, 200 do
  table.insert(old_lines, ("tail %03d"):format(line))
end
vim.api.nvim_buf_set_lines(old_buf, 0, -1, false, old_lines)
vim.cmd("diffthis")

vim.cmd("vnew")
local new_win = vim.api.nvim_get_current_win()
local new_buf = vim.api.nvim_get_current_buf()
local new_lines = { "same", "shared", "changed new", "new only", "end" }
for line = 6, 200 do
  table.insert(new_lines, ("tail %03d"):format(line))
end
vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, new_lines)
vim.cmd("diffthis")
vim.cmd("diffupdate")

diff_buf_win_enter(old_buf, old_win, { symbol = "a", layout_name = "diff2_horizontal" })
diff_buf_win_enter(new_buf, new_win, { symbol = "b", layout_name = "diff2_horizontal" })
expect_source_window(old_win)
expect_source_window(new_win)
for _, win in ipairs({ old_win, new_win }) do
  expect(not vim.wo[win].wrap, "Diffview source windows should not wrap")
  expect(not vim.wo[win].list, "Diffview source windows should hide list characters")
  expect(vim.wo[win].colorcolumn == "80", "Diffview source windows should mark column 80")
end

local function render_statuscolumn(win, line)
  return vim.api.nvim_eval_statusline(vim.wo[win].statuscolumn, {
    winid = win,
    use_statuscol_lnum = line,
    highlights = true,
  })
end

local function has_highlight(rendered, group)
  for _, highlight in ipairs(rendered.highlights) do
    if highlight.group == group then
      return true
    end
  end
  return false
end

vim.wo[old_win].relativenumber = false
local old_change = render_statuscolumn(old_win, 2)
expect(old_change.str:find("▎", 1, true) ~= nil, "the old pane should mark removed lines in its gutter")
expect(has_highlight(old_change, "Removed"), "the old pane gutter should use the removal colour")
expect(old_change.str:match("2%s*$") ~= nil, "the Diffview gutter should retain absolute line numbers")

vim.fn.sign_define("MicrographicsDiffviewSpec", { text = "!", texthl = "Error" })
vim.fn.sign_place(0, "micrographics-diffview-spec", "MicrographicsDiffviewSpec", new_buf, { lnum = 3 })
local new_change = render_statuscolumn(new_win, 3)
expect(new_change.str:find("▎", 1, true) ~= nil, "the new pane should mark added lines in its gutter")
expect(has_highlight(new_change, "Added"), "the new pane gutter should use the addition colour")
expect(new_change.str:find("!", 1, true) == nil, "the Diffview gutter should not render other sign providers")
expect(
  render_statuscolumn(new_win, 2).str:find("▎", 1, true) == nil,
  "unchanged lines should not have a gutter marker"
)
vim.fn.sign_unplace("micrographics-diffview-spec", { buffer = new_buf })
vim.fn.sign_undefine("MicrographicsDiffviewSpec")

diff_buf_win_enter(new_buf, new_win, { symbol = "b", layout_name = "diff3_horizontal" })
local merge_change = render_statuscolumn(new_win, 3)
expect(has_highlight(merge_change, "Changed"), "merge layouts should use a neutral gutter marker")
expect_source_window(new_win)

for _, win in ipairs({ old_win, new_win }) do
  vim.wo[win].foldenable = false
  vim.api.nvim_win_call(win, function()
    vim.cmd("normal! ggzt")
  end)
end
vim.cmd("botright 5new")
local panel_win = vim.api.nvim_get_current_win()
vim.bo.buftype = "nofile"
vim.cmd("syncbind")
view_enter()
vim.cmd("redraw!")
local position = vim.api.nvim_win_get_position(new_win)
vim.api.nvim_input_mouse("move", "", "", 0, position[1] + 5, position[2] + 5)
expect(vim.fn.getmousepos().winid == new_win, "the mouse fixture should target a source pane from the file panel")
local wheel_down = vim.api.nvim_replace_termcodes("<ScrollWheelDown>", true, false, true)
vim.api.nvim_feedkeys(wheel_down:rep(8), "mtx", false)
expect(
  vim.wait(1_000, function()
    return vim.api.nvim_get_current_win() == new_win
  end, 20),
  "mouse scrolling from the file panel should focus the hovered Diffview pane"
)
local old_scroll = vim.api.nvim_win_call(old_win, vim.fn.winsaveview)
local new_scroll = vim.api.nvim_win_call(new_win, vim.fn.winsaveview)
expect(old_scroll.topline > 1 and new_scroll.topline > 1, "the wheel event should scroll both Diffview panes")
expect(old_scroll.lnum == new_scroll.lnum, "mouse scrolling should keep Diffview source panes aligned")

vim.api.nvim_set_current_win(panel_win)
view_leave()
vim.api.nvim_feedkeys(wheel_down, "mtx", false)
vim.wait(50)
expect(vim.api.nvim_get_current_win() == panel_win, "leaving Diffview should restore normal mouse behavior")
vim.cmd("tabclose!")

local large_buffer = vim.api.nvim_create_buf(false, true)
local large_lines = {}
for line = 1, 10000 do
  large_lines[line] = ("large diff line %d"):format(line)
end
vim.api.nvim_buf_set_lines(large_buffer, 0, -1, false, large_lines)
diff_buf_read(large_buffer)
expect(vim.b[large_buffer].diffview_large_buffer == true, "large diff buffers should be marked")
expect(vim.b[large_buffer].completion == false, "large diff buffers should disable completion")
vim.cmd("new")
vim.api.nvim_win_set_buf(0, large_buffer)
local large_window = vim.api.nvim_get_current_win()
diff_buf_win_enter(large_buffer, large_window, { symbol = "b", layout_name = "diff2_horizontal" })
expect(vim.wo[large_window].foldmethod == "manual", "large diff windows should use manual folds")
vim.cmd("bwipeout!")

local test_repo = vim.fn.tempname()
vim.fn.mkdir(test_repo, "p")
local function git(arguments)
  local command = { "git", "-C", test_repo }
  vim.list_extend(command, arguments)
  local result = vim.system(command, { text = true }):wait()
  expect(result.code == 0, table.concat(command, " ") .. " should succeed: " .. (result.stderr or ""))
end

git({ "init", "--quiet" })
git({ "config", "user.name", "Diffview Spec" })
git({ "config", "user.email", "diffview-spec@example.com" })
local test_file = test_repo .. "/example.lua"
vim.fn.writefile({ "return { old = true }" }, test_file)
git({ "add", "example.lua" })
git({ "commit", "--quiet", "-m", "Initial" })
git({ "branch", "-M", "main" })
git({ "update-ref", "refs/remotes/origin/main", "HEAD" })
git({ "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/main" })
git({ "switch", "--quiet", "-c", "feature" })
vim.fn.writefile({ "return { branch = true }" }, test_file)
git({ "add", "example.lua" })
git({ "commit", "--quiet", "-m", "Branch change" })
vim.fn.writefile(
  { "<<<<<<< HEAD", "return { branch = true }", "=======", "return { local_change = true }", ">>>>>>> working" },
  test_file
)

local stage_mapping = configured_diffview_mapping(options, "file_panel", "-")
local prompted = false
local original_confirm = vim.fn.confirm
local diffview_lib = require("diffview.lib")
local original_get_current_view = diffview_lib.get_current_view
vim.fn.confirm = function()
  prompted = true
  return 1
end
diffview_lib.get_current_view = function()
  return {
    infer_cur_file = function()
      return { kind = "working", path = "example.lua", absolute_path = test_file }
    end,
  }
end
local guarded, guard_error = pcall(stage_mapping[3])
vim.fn.confirm = original_confirm
diffview_lib.get_current_view = original_get_current_view
expect(guarded, "the staging guard should run: " .. tostring(guard_error))
expect(prompted, "the staging guard should warn about unresolved conflict markers")
local staged = vim.system({ "git", "-C", test_repo, "diff", "--cached", "--name-only" }, { text = true }):wait()
expect(staged.code == 0 and vim.trim(staged.stdout or "") == "", "cancelled staging should leave the index unchanged")

local original_cwd = vim.fn.getcwd()
vim.cmd("enew")
vim.cmd("lcd " .. vim.fn.fnameescape(test_repo))
local diffview = require("config.diffview")
diffview.open_all_changes()
expect(
  vim.wait(5_000, function()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.wo[win].diff and vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) ~= "diffview://null" then
        return true
      end
    end
    return false
  end, 50),
  "Diffview should load real diff buffers"
)
expect_foreground("DiffviewFilePanelInsertions", "#39d97a")
expect_foreground("DiffviewStatusAdded", "#39d97a")
expect_foreground("DiffviewStatusModified", "#999999")
expect_foreground("DiffviewFilePanelDeletions", "#ff3b2f")
expect_foreground("DiffviewStatusDeleted", "#ff3b2f")
expect_background_only("DiffviewDiffAdd", "#102419")
expect_background_only("DiffviewDiffChange", "#1c1c1c")
expect_background_only("DiffviewDiffText", "#333333")
expect_background_only("DiffviewDiffAddAsDelete", "#2a1514")
expect_unstyled("MicrographicsDiffviewSource")

local view = require("diffview.lib").get_current_view()
expect(view ~= nil, "Diffview should open a view")
expect(vim.t.diffview_context == "feature", "full-branch diffs should identify their branch")
expect(view.panel:get_config().position == "right", "Diffview file panel should open on the right")
local source_windows = 0
local source_sides = {}
local local_buffer
for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
  if vim.wo[win].diff then
    source_windows = source_windows + 1
    source_sides[vim.w[win].micrographics_diffview_gutter_hl] = true
    expect_source_window(win)
    local buffer = vim.api.nvim_win_get_buf(win)
    if vim.bo[buffer].buftype == "" and vim.endswith(vim.api.nvim_buf_get_name(buffer), "/example.lua") then
      local_buffer = buffer
    end
  end
end
expect(source_windows == 2, "Diffview should install the gutter in both source panes")
expect(source_sides.Removed and source_sides.Added, "Diffview should identify its old and new panes")
if local_buffer and package.loaded.gitsigns then
  vim.wait(1_000, function()
    return vim.b[local_buffer].gitsigns_status_dict ~= nil
  end, 50)
  require("gitsigns").detach(local_buffer)
end

vim.cmd("DiffviewClose")
diffview.open_all_changes_history()
expect(
  vim.wait(5_000, function()
    local history_view = require("diffview.lib").get_current_view()
    local panel = history_view and history_view.panel
    return panel and panel.updating == false and type(panel.entries) == "table" and #panel.entries > 0
  end, 50),
  "Diffview should load full-branch history"
)
expect(vim.t.diffview_context == "feature", "full-branch history should identify its branch")
vim.cmd("DiffviewClose")
vim.cmd("lcd " .. vim.fn.fnameescape(original_cwd))
vim.fn.delete(test_repo, "rf")

expect_command_mapping("<leader>gd", "DiffviewOpen", "Git Diff (Working Tree)")
expect_function_mapping("<leader>gD", "Git Diff (Full Branch)")
expect_function_mapping("<leader>gA", "Git Diff (Full Branch by Commit)")
expect_function_mapping("<leader>gV", "Git Diff (Current PR Layer)")
expect_command_mapping("<leader>gq", "DiffviewClose", "Close Diffview")
expect_command_mapping("<leader>gF", "DiffviewFileHistory --base=LOCAL %", "Git Current File History (Diffview)")
expect_command_mapping(
  "<leader>gR",
  "DiffviewFileHistory --follow --base=LOCAL %",
  "Git Current File History (Follow Renames)"
)
expect_command_mapping("<leader>gH", "DiffviewFileHistory", "Git History (Diffview)")
expect_command_mapping("<leader>gm", "DiffviewOpen HEAD~1", "Git Diff (Last Commit to Working Tree)")
expect_command_mapping("<leader>gM", "DiffviewOpen HEAD~1..HEAD", "Git Diff (Last Commit)")
expect(configured_mapping("<leader>gf") == nil, "Diffview should preserve LazyVim's file-history picker")

for _, lhs in ipairs({ "-", "s", "S", "<leader>cw" }) do
  local mapping = configured_diffview_mapping(options, "file_panel", lhs)
  expect(mapping ~= nil and type(mapping[3]) == "function", lhs .. " should use a guarded Diffview action")
end
local merge_mapping = configured_diffview_mapping(options, "view", "<leader>cw")
expect(merge_mapping ~= nil and type(merge_mapping[3]) == "function", "Diffview views should save resolved merge files")

vim.t.diffview_context = nil
expect(not diffview.has_statusline_context(), "ordinary tabs should not show Diffview context")
vim.t.diffview_context = "feature  PR #42"
expect(diffview.statusline() == "feature  PR #42", "Diffview context should include the branch and pull request")
vim.t.diffview_context = nil

print(("diffview: %d checks passed"):format(checks))
