local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(source))
local spec = dofile(root .. "/lua/plugins/diffview.lua")
local checks = 0

local function expect(condition, message)
  checks = checks + 1
  assert(condition, message)
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

vim.wait(1_000, function()
  return vim.fn.exists(":DiffviewOpen") == 2
end)

expect(vim.fn.exists(":DiffviewOpen") == 2, ":DiffviewOpen should be registered")
expect(vim.fn.exists(":DiffviewFileHistory") == 2, ":DiffviewFileHistory should be registered")
expect_mapping("<leader>gd", "DiffviewOpen HEAD", "Git Diff (Working Tree)")
expect_mapping(
  "<leader>gD",
  "DiffviewOpen origin/HEAD...HEAD --imply-local",
  "Git Diff (Full Branch)"
)
expect_mapping("<leader>gq", "DiffviewClose", "Close Diffview")
expect_mapping("<leader>gF", "DiffviewFileHistory %", "Git Current File History (Diffview)")
expect_mapping("<leader>gH", "DiffviewFileHistory", "Git History (Diffview)")

print(("diffview: %d checks passed"):format(checks))
