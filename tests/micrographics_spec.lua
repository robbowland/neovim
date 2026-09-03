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

local function expect_highlight(name, expected, absent)
  local actual = vim.api.nvim_get_hl(0, { name = name, link = false })
  for key, value in pairs(expected) do
    local wanted = (key == "fg" or key == "bg" or key == "sp") and hex(value) or value
    expect(
      actual[key] == wanted,
      ("%s.%s: expected %s, got %s"):format(name, key, tostring(wanted), tostring(actual[key]))
    )
  end
  for _, key in ipairs(absent or {}) do
    expect(actual[key] == nil, ("%s.%s: expected no value, got %s"):format(name, key, tostring(actual[key])))
  end
end

local standard_captures = {
  "@variable",
  "@variable.builtin",
  "@variable.parameter",
  "@variable.parameter.builtin",
  "@variable.member",
  "@constant",
  "@constant.builtin",
  "@constant.macro",
  "@module",
  "@module.builtin",
  "@label",
  "@string",
  "@string.documentation",
  "@string.regexp",
  "@string.escape",
  "@string.special",
  "@string.special.symbol",
  "@string.special.path",
  "@string.special.url",
  "@character",
  "@character.special",
  "@boolean",
  "@number",
  "@number.float",
  "@type",
  "@type.builtin",
  "@type.definition",
  "@attribute",
  "@attribute.builtin",
  "@property",
  "@function",
  "@function.builtin",
  "@function.call",
  "@function.macro",
  "@function.method",
  "@function.method.call",
  "@constructor",
  "@operator",
  "@keyword",
  "@keyword.coroutine",
  "@keyword.function",
  "@keyword.operator",
  "@keyword.import",
  "@keyword.type",
  "@keyword.modifier",
  "@keyword.repeat",
  "@keyword.return",
  "@keyword.debug",
  "@keyword.exception",
  "@keyword.conditional",
  "@keyword.conditional.ternary",
  "@keyword.directive",
  "@keyword.directive.define",
  "@punctuation.delimiter",
  "@punctuation.bracket",
  "@punctuation.special",
  "@comment",
  "@comment.documentation",
  "@comment.error",
  "@comment.warning",
  "@comment.todo",
  "@comment.note",
  "@markup.strong",
  "@markup.italic",
  "@markup.strikethrough",
  "@markup.underline",
  "@markup.heading",
  "@markup.heading.1",
  "@markup.heading.2",
  "@markup.heading.3",
  "@markup.heading.4",
  "@markup.heading.5",
  "@markup.heading.6",
  "@markup.quote",
  "@markup.math",
  "@markup.link",
  "@markup.link.label",
  "@markup.link.url",
  "@markup.raw",
  "@markup.raw.block",
  "@markup.list",
  "@markup.list.checked",
  "@markup.list.unchecked",
  "@diff.plus",
  "@diff.minus",
  "@diff.delta",
  "@tag",
  "@tag.builtin",
  "@tag.attribute",
  "@tag.delimiter",
  "@conceal",
  "@none",
}

local function expect_tree_sitter_coverage()
  local groups = require("micrographics").groups("dark")
  for _, capture in ipairs(standard_captures) do
    expect(groups[capture] ~= nil, capture .. " should be defined by Micrographics")
  end

  local ignored_captures = { spell = true, nospell = true }
  local languages = {}
  for _, parser_path in ipairs(vim.api.nvim_get_runtime_file("parser/*.so", true)) do
    languages[vim.fs.basename(parser_path):gsub("%.so$", "")] = true
  end

  for language in pairs(languages) do
    local ok, query = pcall(vim.treesitter.query.get, language, "highlights")
    expect(ok, language .. " highlights query should load")
    if ok and query then
      for _, capture in ipairs(query.captures) do
        if not capture:match("^_") and not ignored_captures[capture] then
          expect(
            groups["@" .. capture] ~= nil,
            ("@%s used by %s should be defined by Micrographics"):format(capture, language)
          )
        end
      end
    end
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
    vim.api.nvim_set_hl(0, "lualine_x_diff_added", { fg = "#123456", bg = "#654321" })
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
expect(require("micrographics").palette("dark").success == "#39d97a", "dark success should use canonical green")
expect_tree_sitter_coverage()
expect_highlight("Normal", { fg = "#ffffff", bg = "#000000" })
expect_highlight("Comment", { fg = "#999999", italic = true })
expect_highlight("@string.documentation", { fg = "#999999", italic = true })
expect_highlight("@string.special.path", { fg = "#ffffff" })
expect_highlight("@string.special.url", { fg = "#999999", underline = true })
expect_highlight("@character.special", { fg = "#ffffff" })
expect_highlight("@attribute.builtin", { fg = "#ffffff" })
expect_highlight("@keyword.debug", { fg = "#404040", italic = true })
expect_highlight("@comment.error", { fg = "#ff3b2f" })
expect_highlight("@comment.warning", { fg = "#ff3b2f" })
expect_highlight("@comment.todo", { fg = "#ffffff", bold = true })
expect_highlight("@comment.note", { fg = "#999999", bold = true })
expect_highlight("Keyword", { fg = "#404040", italic = true })
expect_highlight("Type", { fg = "#ffffff" })
expect_highlight("Function", { fg = "#ffffff", bold = true })
expect_highlight("@variable.builtin", { fg = "#ffffff" })
expect_highlight("@lsp.mod.defaultLibrary", { fg = "#ffffff" })
expect_highlight("LspInlayHint", { fg = "#404040", bg = "#000000" })
expect_highlight("@punctuation.bracket", { fg = "#404040" })
expect_highlight("@micrographics.punctuation", { fg = "#404040" })
expect_highlight("SnacksIndent", { fg = "#000000" })
expect_highlight("SnacksIndentScope", { fg = "#404040" })
expect(not vim.api.nvim_get_hl(0, { name = "CursorLine", link = false }).underline, "CursorLine should not underline")
expect(vim.fn.exists(":MicrographicsPunctuation") == 2, "punctuation command should exist")
vim.cmd("MicrographicsPunctuation ink")
expect_highlight("@punctuation.bracket", { fg = "#ffffff" })
expect_highlight("@micrographics.punctuation", { fg = "#ffffff" })
vim.cmd("MicrographicsPunctuation faint")
expect_highlight("DiagnosticError", { fg = "#ff3b2f" })
expect_highlight("Added", { fg = "#39d97a" })
expect_highlight("diffAdded", { fg = "#39d97a" })
expect_highlight("DiffAdd", { bg = "#102419" }, { "fg", "bold" })
expect_highlight("DiffChange", { bg = "#1c1c1c" }, { "fg", "bold" })
expect_highlight("DiffDelete", { bg = "#2a1514" }, { "fg", "bold" })
expect_highlight("DiffText", { bg = "#333333" }, { "fg", "bold" })
expect_highlight("DiffTextAdd", { bg = "#333333" }, { "fg", "bold" })
expect_highlight("MicrographicsDiffviewSource", {}, { "fg", "bg", "bold" })
expect_highlight("OkMsg", { fg = "#39d97a" })
expect_highlight("DiagnosticOk", { fg = "#39d97a" })
expect_highlight("DiagnosticVirtualTextOk", { fg = "#39d97a", italic = true })
expect_highlight("DiagnosticUnderlineOk", { sp = "#39d97a", underline = true })
expect_highlight("Visual", { fg = "#000000", bg = "#ffffff" })
expect_highlight("SnacksPickerSelection", { fg = "#000000", bg = "#ffffff", bold = true })
expect_highlight("SnacksPickerGitStatusAdded", { fg = "#39d97a" })
expect_highlight("SnacksDiffAdd", { fg = "#39d97a" })
expect_highlight("NoiceCmdlineIconCmdline", { fg = "#ffffff" })
expect_highlight("StatusLine", { fg = "#404040", bg = "#000000" })
expect_highlight("WinBar", { fg = "#999999", bg = "#000000" })
expect_highlight("TabLineSel", { fg = "#999999", bg = "#000000", bold = true })
expect_highlight("lualine_z_normal", { fg = "#404040", bg = "#000000" })
expect_highlight("lualine_z_command", { fg = "#ff3b2f", bg = "#000000", bold = true })
expect_highlight("lualine_x_diff_added", { fg = "#39d97a", bg = "#000000" })
expect_highlight("LazyProgressDone", { fg = "#39d97a" })
expect_highlight("NeotestPassed", { fg = "#39d97a" })
expect_highlight("GitSignsAdd", { fg = "#39d97a" })
expect_highlight("GitSignsUntracked", { fg = "#39d97a" })
expect_highlight("GitSignsAddInline", { fg = "#39d97a", bg = "#000000" })
expect_highlight("RenderMarkdownSuccess", { fg = "#39d97a" })
expect_highlight("DevIconLua", { fg = "#999999" })
expect(vim.g.terminal_color_1 == "#ff3b2f", "terminal danger colour should match the theme")
expect(vim.g.terminal_color_2 == "#39d97a", "terminal success colour should match the theme")
expect(vim.g.terminal_color_10 == "#39d97a", "terminal bright success colour should match the theme")

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

expect(require("micrographics").palette("light").success == "#39d97a", "light success should use canonical green")
expect_highlight("Normal", { fg = "#000000", bg = "#ffffff" })
expect_highlight("Added", { fg = "#39d97a" })
expect_highlight("diffAdded", { fg = "#39d97a" })
expect_highlight("DiffAdd", { bg = "#e8f3ec" }, { "fg", "bold" })
expect_highlight("DiffChange", { bg = "#eeeeee" }, { "fg", "bold" })
expect_highlight("DiffDelete", { bg = "#f8e9e8" }, { "fg", "bold" })
expect_highlight("DiffText", { bg = "#d8d8d8" }, { "fg", "bold" })
expect_highlight("DiffTextAdd", { bg = "#d8d8d8" }, { "fg", "bold" })
expect_highlight("MicrographicsDiffviewSource", {}, { "fg", "bg", "bold" })
expect_highlight("Comment", { fg = "#666666", italic = true })
expect_highlight("@string.documentation", { fg = "#666666", italic = true })
expect_highlight("Keyword", { fg = "#bfbfbf", italic = true })
expect_highlight("Type", { fg = "#000000" })
expect_highlight("@variable.builtin", { fg = "#000000" })
expect_highlight("@lsp.mod.defaultLibrary", { fg = "#000000" })
expect_highlight("LspInlayHint", { fg = "#bfbfbf", bg = "#ffffff" })
expect_highlight("DiagnosticError", { fg = "#c81e1e" })
expect_highlight("Visual", { fg = "#ffffff", bg = "#000000" })

for _, language in ipairs({ "javascript", "typescript", "tsx" }) do
  local query_path = root .. "/after/queries/" .. language .. "/highlights.scm"
  local query_source = table.concat(vim.fn.readfile(query_path), "\n")
  local ok = pcall(vim.treesitter.query.parse, language, query_source)
  expect(ok, language .. " punctuation query should parse")
end

print(("micrographics: %d checks passed"):format(checks))
