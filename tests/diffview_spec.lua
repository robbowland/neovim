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

local function expect_mapping(lhs, command, description)
  local configured
  for _, mapping in ipairs(spec.keys) do
    if mapping[1] == lhs then
      configured = mapping
      break
    end
  end

  expect(configured ~= nil, lhs .. " should be mapped")
  expect(configured[2] == "<cmd>" .. command .. "<cr>", lhs .. " should run " .. command)
  expect(configured.desc == description, lhs .. " should be described as " .. description)
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
expect(spec.opts.enhanced_diff_hl == nil, "Diffview should not add body highlighting outside the gutter")

local diff_buf_win_enter = spec.opts.hooks and spec.opts.hooks.diff_buf_win_enter
expect(type(diff_buf_win_enter) == "function", "Diffview should configure gutter markers for diff windows")

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
vim.api.nvim_buf_set_lines(old_buf, 0, -1, false, { "same", "old only", "shared", "changed old", "end" })
vim.cmd("diffthis")

vim.cmd("vnew")
local new_win = vim.api.nvim_get_current_win()
local new_buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, { "same", "shared", "changed new", "new only", "end" })
vim.cmd("diffthis")
vim.cmd("diffupdate")

diff_buf_win_enter(old_buf, old_win, { symbol = "a", layout_name = "diff2_horizontal" })
diff_buf_win_enter(new_buf, new_win, { symbol = "b", layout_name = "diff2_horizontal" })
expect_source_window(old_win)
expect_source_window(new_win)

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
vim.cmd("tabclose!")

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
vim.fn.writefile({ "return { new = true }" }, test_file)

local original_cwd = vim.fn.getcwd()
vim.cmd("lcd " .. vim.fn.fnameescape(test_repo))
vim.cmd("DiffviewOpen HEAD")
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
vim.cmd("lcd " .. vim.fn.fnameescape(original_cwd))
vim.fn.delete(test_repo, "rf")

expect_mapping("<leader>gd", "DiffviewOpen HEAD", "Git Diff (Working Tree)")
expect_mapping("<leader>gD", "DiffviewOpen origin/HEAD...HEAD --imply-local", "Git Diff (Full Branch)")
expect_mapping("<leader>gq", "DiffviewClose", "Close Diffview")
expect_mapping("<leader>gF", "DiffviewFileHistory %", "Git Current File History (Diffview)")
expect_mapping("<leader>gH", "DiffviewFileHistory", "Git History (Diffview)")

print(("diffview: %d checks passed"):format(checks))
