local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(source))
vim.opt.runtimepath:prepend(root)
vim.opt.termguicolors = true

local checks = 0

local function expect(condition, message)
  checks = checks + 1
  assert(condition, message)
end

local function hex(value)
  return tonumber(value:sub(2), 16)
end

local function expect_highlight(name, expected)
  local actual = vim.api.nvim_get_hl(0, { name = name, link = false })
  for key, value in pairs(expected) do
    local wanted = (key == "fg" or key == "bg" or key == "sp") and hex(value) or value
    expect(
      actual[key] == wanted,
      ("%s.%s: expected %s, got %s"):format(name, key, tostring(wanted), tostring(actual[key]))
    )
  end
end

local override_group = vim.api.nvim_create_augroup("MicrographicsSpecOverrides", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
  group = override_group,
  pattern = "micrographics",
  callback = function()
    vim.api.nvim_set_hl(0, "NoiceCmdlineIconCmdline", { fg = "#123456" })
    vim.api.nvim_set_hl(0, "lualine_z_normal", { fg = "#123456", bg = "#654321" })
    vim.api.nvim_set_hl(0, "lualine_z_command", { fg = "#123456", bg = "#654321" })
    vim.api.nvim_set_hl(0, "DevIconLua", { fg = "#123456" })
  end,
})

vim.g.micrographics_punctuation = nil
vim.o.background = "dark"
vim.cmd("colorscheme micrographics")
vim.wait(100, function()
  return false
end)

expect(vim.g.colors_name == "micrographics", "colorscheme should identify itself")
expect_highlight("Normal", { fg = "#ffffff", bg = "#000000" })
expect_highlight("Comment", { fg = "#999999", italic = true })
expect_highlight("Keyword", { fg = "#616161", italic = true })
expect_highlight("Type", { fg = "#ffffff" })
expect_highlight("Function", { fg = "#ffffff", bold = true })
expect_highlight("@variable.builtin", { fg = "#ffffff" })
expect_highlight("@lsp.mod.defaultLibrary", { fg = "#ffffff" })
expect_highlight("LspInlayHint", { fg = "#616161", bg = "#000000" })
expect_highlight("@punctuation.bracket", { fg = "#616161" })
expect_highlight("@micrographics.punctuation", { fg = "#616161" })
expect_highlight("SnacksIndent", { fg = "#000000" })
expect_highlight("SnacksIndentScope", { fg = "#616161" })
expect(not vim.api.nvim_get_hl(0, { name = "CursorLine", link = false }).underline, "CursorLine should not underline")
expect(vim.fn.exists(":MicrographicsPunctuation") == 2, "punctuation command should exist")
vim.cmd("MicrographicsPunctuation ink")
expect_highlight("@punctuation.bracket", { fg = "#ffffff" })
expect_highlight("@micrographics.punctuation", { fg = "#ffffff" })
vim.cmd("MicrographicsPunctuation faint")
expect_highlight("DiagnosticError", { fg = "#ff3b2f" })
expect_highlight("Visual", { fg = "#000000", bg = "#ffffff" })
expect_highlight("SnacksPickerSelection", { fg = "#000000", bg = "#ffffff", bold = true })
expect_highlight("NoiceCmdlineIconCmdline", { fg = "#ffffff" })
expect_highlight("StatusLine", { fg = "#616161", bg = "#000000" })
expect_highlight("WinBar", { fg = "#999999", bg = "#000000" })
expect_highlight("TabLineSel", { fg = "#999999", bg = "#000000", bold = true })
expect_highlight("lualine_z_normal", { fg = "#616161", bg = "#000000" })
expect_highlight("lualine_z_command", { fg = "#ff3b2f", bg = "#000000", bold = true })
expect_highlight("DevIconLua", { fg = "#999999" })
expect(vim.g.terminal_color_1 == "#ff3b2f", "terminal danger colour should match the theme")

for variant_name, palette in pairs({
  dark = require("micrographics").palette("dark"),
  light = require("micrographics").palette("light"),
}) do
  local allowed = {}
  for _, color in pairs(palette) do
    allowed[color] = true
  end

  for group_name, spec in pairs(require("micrographics").groups(variant_name)) do
    for _, key in ipairs({ "fg", "bg", "sp" }) do
      local color = spec[key]
      expect(
        color == nil or allowed[color],
        ("%s.%s uses colour outside the %s semantic palette: %s"):format(group_name, key, variant_name, tostring(color))
      )
    end
  end
end

vim.o.background = "light"
vim.cmd("colorscheme micrographics")
vim.wait(100, function()
  return false
end)

expect_highlight("Normal", { fg = "#000000", bg = "#ffffff" })
expect_highlight("Comment", { fg = "#666666", italic = true })
expect_highlight("Keyword", { fg = "#9e9e9e", italic = true })
expect_highlight("Type", { fg = "#000000" })
expect_highlight("@variable.builtin", { fg = "#000000" })
expect_highlight("@lsp.mod.defaultLibrary", { fg = "#000000" })
expect_highlight("LspInlayHint", { fg = "#9e9e9e", bg = "#ffffff" })
expect_highlight("DiagnosticError", { fg = "#c81e1e" })
expect_highlight("Visual", { fg = "#ffffff", bg = "#000000" })

for _, language in ipairs({ "javascript", "typescript", "tsx" }) do
  local query_path = root .. "/after/queries/" .. language .. "/highlights.scm"
  local query_source = table.concat(vim.fn.readfile(query_path), "\n")
  local ok = pcall(vim.treesitter.query.parse, language, query_source)
  expect(ok, language .. " punctuation query should parse")
end

print(("micrographics: %d checks passed"):format(checks))
