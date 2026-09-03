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
  expect(actual.fg == nil, name .. " should preserve the file's syntax foreground")
  expect(actual.bold == nil, name .. " should preserve the file's normal text weight")
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
expect(spec.opts.enhanced_diff_hl == true, "Diffview should subtly render deletion filler")

vim.cmd("DiffviewOpen HEAD")
expect(
  vim.wait(1_000, function()
    return package.loaded["diffview"] ~= nil
  end),
  "Diffview should load"
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
local view = require("diffview.lib").get_current_view()
expect(view ~= nil, "Diffview should open a view")
expect(view.panel:get_config().position == "right", "Diffview file panel should open on the right")
vim.cmd("DiffviewClose")

expect_mapping("<leader>gd", "DiffviewOpen HEAD", "Git Diff (Working Tree)")
expect_mapping("<leader>gD", "DiffviewOpen origin/HEAD...HEAD --imply-local", "Git Diff (Full Branch)")
expect_mapping("<leader>gq", "DiffviewClose", "Close Diffview")
expect_mapping("<leader>gF", "DiffviewFileHistory %", "Git Current File History (Diffview)")
expect_mapping("<leader>gH", "DiffviewFileHistory", "Git History (Diffview)")

print(("diffview: %d checks passed"):format(checks))
