local M = {}

local function set_many(groups, names, value)
  for _, name in ipairs(names) do
    groups[name] = vim.deepcopy(value)
  end
end

local function link_many(groups, names, target)
  set_many(groups, names, { link = target })
end

function M.build(p, options)
  options = options or {}
  local punctuation = options.punctuation == "faint" and p.faint or p.ink

  local groups = {
    -- Editor and terminal chrome ------------------------------------------------
    Normal = { fg = p.ink, bg = p.paper },
    NormalNC = { fg = p.ink, bg = p.paper },
    NormalFloat = { fg = p.ink, bg = p.paper },
    FloatBorder = { fg = p.metadata, bg = p.paper },
    FloatTitle = { fg = p.ink, bg = p.paper, bold = true },
    FloatFooter = { fg = p.faint, bg = p.paper },
    Cursor = { fg = p.paper, bg = p.ink },
    lCursor = { fg = p.paper, bg = p.ink },
    CursorIM = { fg = p.paper, bg = p.ink },
    TermCursor = { fg = p.paper, bg = p.ink },
    TermCursorNC = { fg = p.metadata, bg = p.paper },
    CursorLine = { bg = p.paper },
    CursorColumn = { bg = p.paper },
    ColorColumn = { bg = p.faint },
    LineNr = { fg = p.faint, bg = p.paper },
    LineNrAbove = { fg = p.faint, bg = p.paper },
    LineNrBelow = { fg = p.faint, bg = p.paper },
    CursorLineNr = { fg = p.ink, bg = p.paper, bold = true },
    CursorLineFold = { fg = p.metadata, bg = p.paper },
    CursorLineSign = { fg = p.metadata, bg = p.paper },
    SignColumn = { fg = p.metadata, bg = p.paper },
    FoldColumn = { fg = p.faint, bg = p.paper },
    Folded = { fg = p.metadata, bg = p.paper, italic = true },
    WinSeparator = { fg = p.metadata, bg = p.paper },
    VertSplit = { fg = p.metadata, bg = p.paper },
    EndOfBuffer = { fg = p.faint, bg = p.paper },
    NonText = { fg = p.faint },
    Whitespace = { fg = p.faint },
    SpecialKey = { fg = p.faint },
    Conceal = { fg = p.faint },
    Visual = { fg = p.paper, bg = p.ink },
    VisualNOS = { fg = p.paper, bg = p.ink },
    Search = { fg = p.paper, bg = p.ink, bold = true },
    IncSearch = { fg = p.paper, bg = p.danger, bold = true },
    CurSearch = { fg = p.paper, bg = p.danger, bold = true },
    Substitute = { fg = p.paper, bg = p.danger, bold = true },
    MatchParen = { fg = p.paper, bg = p.ink, bold = true },
    QuickFixLine = { fg = p.paper, bg = p.ink, bold = true },
    Pmenu = { fg = p.ink, bg = p.paper },
    PmenuSel = { fg = p.paper, bg = p.ink, bold = true },
    PmenuKind = { fg = p.metadata, bg = p.paper },
    PmenuKindSel = { fg = p.paper, bg = p.ink, bold = true },
    PmenuExtra = { fg = p.faint, bg = p.paper },
    PmenuExtraSel = { fg = p.paper, bg = p.ink },
    PmenuSbar = { bg = p.paper },
    PmenuThumb = { bg = p.faint },
    WildMenu = { fg = p.paper, bg = p.ink, bold = true },
    StatusLine = { fg = p.faint, bg = p.paper },
    StatusLineNC = { fg = p.faint, bg = p.paper },
    WinBar = { fg = p.metadata, bg = p.paper },
    WinBarNC = { fg = p.faint, bg = p.paper },
    TabLine = { fg = p.faint, bg = p.paper },
    TabLineFill = { fg = p.faint, bg = p.paper },
    TabLineSel = { fg = p.metadata, bg = p.paper, bold = true },
    MsgArea = { fg = p.ink, bg = p.paper },
    MsgSeparator = { fg = p.faint, bg = p.paper },
    ModeMsg = { fg = p.ink, bold = true },
    MoreMsg = { fg = p.ink },
    OkMsg = { fg = p.success },
    Question = { fg = p.ink, bold = true },
    ErrorMsg = { fg = p.danger, bold = true },
    WarningMsg = { fg = p.danger, bold = true },
    FloatShadow = { bg = p.paper, blend = 100 },
    FloatShadowThrough = { bg = p.paper, blend = 100 },
    PmenuShadow = { bg = p.paper, blend = 100 },
    PmenuShadowThrough = { bg = p.paper, blend = 100 },
    NvimFigureBrace = { fg = p.danger, bg = p.paper },
    NvimInternalError = { fg = p.danger, bg = p.paper, bold = true },
    NvimInvalidSingleQuotedUnknownEscape = { fg = p.danger, bg = p.paper },
    NvimSingleQuotedUnknownEscape = { fg = p.danger, bg = p.paper },
    RedrawDebugClear = { fg = p.ink, bg = p.paper },
    RedrawDebugComposed = { fg = p.ink, bg = p.paper },
    RedrawDebugRecompose = { fg = p.danger, bg = p.paper },
    Directory = { fg = p.ink, bold = true },
    Title = { fg = p.ink, bold = true },

    -- Legacy syntax: semantic anchors in ink, scaffolding in grey --------------
    Comment = { fg = p.metadata, italic = true },
    Constant = { fg = p.ink },
    String = { fg = p.ink },
    Character = { fg = p.ink },
    Number = { fg = p.ink },
    Boolean = { fg = p.ink },
    Float = { fg = p.ink },
    Identifier = { fg = p.ink },
    Function = { fg = p.ink, bold = true },
    Statement = { fg = p.faint, italic = true },
    Conditional = { fg = p.faint, italic = true },
    Repeat = { fg = p.faint, italic = true },
    Label = { fg = p.faint, italic = true },
    Operator = { fg = p.faint },
    Keyword = { fg = p.faint, italic = true },
    Exception = { fg = p.faint, italic = true },
    PreProc = { fg = p.metadata },
    Include = { fg = p.faint, italic = true },
    Define = { fg = p.metadata },
    Macro = { fg = p.metadata },
    PreCondit = { fg = p.metadata },
    Type = { fg = p.ink },
    StorageClass = { fg = p.faint, italic = true },
    Structure = { fg = p.faint },
    Typedef = { fg = p.faint },
    Special = { fg = p.metadata },
    SpecialChar = { fg = p.ink },
    Tag = { fg = p.ink },
    Delimiter = { fg = p.faint },
    SpecialComment = { fg = p.metadata, italic = true },
    Debug = { fg = p.danger },
    Underlined = { fg = p.ink, underline = true },
    Ignore = { fg = p.faint },
    Error = { fg = p.danger, bold = true },
    Todo = { fg = p.ink, bold = true },
    Bold = { bold = true },
    Italic = { italic = true },

    -- Diff and version-control state -------------------------------------------
    Added = { fg = p.success },
    Changed = { fg = p.metadata },
    Removed = { fg = p.danger },
    DiffAdd = { fg = p.success, bg = p.paper },
    DiffChange = { fg = p.metadata, bg = p.paper },
    DiffDelete = { fg = p.danger, bg = p.paper },
    DiffText = { fg = p.paper, bg = p.ink, bold = true },

    -- Diagnostics: glyph and text carry state; red only escalates ---------------
    DiagnosticError = { fg = p.danger },
    DiagnosticWarn = { fg = p.danger },
    DiagnosticInfo = { fg = p.ink },
    DiagnosticHint = { fg = p.metadata },
    DiagnosticOk = { fg = p.success },
    DiagnosticVirtualTextError = { fg = p.danger, italic = true },
    DiagnosticVirtualTextWarn = { fg = p.danger, italic = true },
    DiagnosticVirtualTextInfo = { fg = p.metadata, italic = true },
    DiagnosticVirtualTextHint = { fg = p.faint, italic = true },
    DiagnosticVirtualTextOk = { fg = p.success, italic = true },
    DiagnosticUnderlineError = { undercurl = true, sp = p.danger },
    DiagnosticUnderlineWarn = { undercurl = true, sp = p.danger },
    DiagnosticUnderlineInfo = { underline = true, sp = p.metadata },
    DiagnosticUnderlineHint = { underline = true, sp = p.faint },
    DiagnosticUnderlineOk = { underline = true, sp = p.success },
    DiagnosticUnnecessary = { fg = p.faint },
    DiagnosticDeprecated = { fg = p.faint, strikethrough = true },

    -- LSP dynamic work signals --------------------------------------------------
    LspReferenceText = { fg = p.ink, bg = p.faint },
    LspReferenceRead = { fg = p.ink, bg = p.faint },
    LspReferenceWrite = { fg = p.paper, bg = p.ink, bold = true },
    LspSignatureActiveParameter = { fg = p.paper, bg = p.ink, bold = true },
    LspCodeLens = { fg = p.faint },
    LspCodeLensSeparator = { fg = p.faint },
    LspInlayHint = { fg = p.faint, bg = p.paper },

    -- Spell checking ------------------------------------------------------------
    SpellBad = { undercurl = true, sp = p.danger },
    SpellCap = { undercurl = true, sp = p.danger },
    SpellLocal = { underline = true, sp = p.metadata },
    SpellRare = { underline = true, sp = p.faint },
  }

  -- Treesitter syntax ----------------------------------------------------------
  link_many(groups, { "@comment", "@comment.documentation", "@string.documentation" }, "Comment")
  link_many(groups, { "@constant", "@constant.macro" }, "Constant")
  link_many(groups, { "@constant.builtin" }, "Special")
  link_many(groups, {
    "@string",
    "@string.escape",
    "@string.regexp",
    "@string.special",
    "@string.special.symbol",
    "@string.special.path",
    "@character",
    "@character.special",
  }, "String")
  groups["@string.special.url"] = { fg = p.metadata, underline = true }
  link_many(groups, { "@number", "@number.float", "@boolean" }, "Number")
  link_many(groups, { "@variable", "@variable.parameter", "@variable.member", "@property" }, "Identifier")
  link_many(groups, { "@variable.builtin", "@variable.parameter.builtin" }, "Identifier")
  link_many(
    groups,
    { "@function", "@function.call", "@function.method", "@function.method.call", "@function.macro" },
    "Function"
  )
  link_many(groups, { "@function.builtin", "@constructor" }, "Function")
  link_many(groups, { "@module", "@module.builtin", "@namespace" }, "Type")
  link_many(
    groups,
    { "@type", "@type.builtin", "@type.definition", "@type.qualifier", "@attribute", "@attribute.builtin" },
    "Type"
  )
  link_many(groups, {
    "@keyword",
    "@keyword.coroutine",
    "@keyword.function",
    "@keyword.operator",
    "@keyword.import",
    "@keyword.type",
    "@keyword.modifier",
    "@keyword.debug",
  }, "Keyword")
  link_many(groups, {
    "@keyword.conditional",
    "@keyword.conditional.ternary",
    "@keyword.repeat",
    "@keyword.return",
    "@keyword.exception",
    "@keyword.directive",
    "@keyword.directive.define",
  }, "Conditional")
  link_many(groups, { "@operator" }, "Operator")
  link_many(groups, { "@punctuation.delimiter", "@punctuation.special" }, "Delimiter")
  groups["@punctuation.bracket"] = { fg = punctuation }
  groups["@micrographics.punctuation"] = { fg = punctuation }
  link_many(groups, { "@tag", "@tag.builtin" }, "Tag")
  link_many(groups, { "@tag.attribute" }, "Identifier")
  link_many(groups, { "@tag.delimiter" }, "Delimiter")
  link_many(groups, { "@label" }, "Label")
  link_many(groups, { "@conceal" }, "Conceal")
  link_many(groups, { "@none" }, "Normal")
  link_many(groups, { "@comment.error" }, "DiagnosticError")
  link_many(groups, { "@comment.warning" }, "DiagnosticWarn")
  link_many(groups, { "@comment.todo" }, "Todo")
  groups["@comment.note"] = { fg = p.metadata, bold = true }

  -- Markup keeps structure legible without a second colour system --------------
  groups["@markup.heading.1"] = { fg = p.ink, bold = true }
  groups["@markup.heading.2"] = { fg = p.ink, bold = true }
  groups["@markup.heading.3"] = { fg = p.metadata, bold = true }
  groups["@markup.heading.4"] = { fg = p.metadata }
  groups["@markup.heading.5"] = { fg = p.faint }
  groups["@markup.heading.6"] = { fg = p.faint }
  link_many(groups, { "@markup.heading", "@markup.title" }, "Title")
  link_many(groups, { "@markup.strong" }, "Bold")
  link_many(groups, { "@markup.italic" }, "Italic")
  groups["@markup.strikethrough"] = { fg = p.faint, strikethrough = true }
  groups["@markup.underline"] = { fg = p.ink, underline = true }
  groups["@markup.link"] = { fg = p.ink }
  groups["@markup.link.label"] = { fg = p.ink, bold = true }
  groups["@markup.link.url"] = { fg = p.metadata, underline = true }
  groups["@markup.raw"] = { fg = p.ink }
  groups["@markup.raw.block"] = { fg = p.ink }
  groups["@markup.math"] = { fg = p.ink }
  groups["@markup.quote"] = { fg = p.metadata, italic = true }
  groups["@markup.list"] = { fg = p.faint }
  groups["@markup.list.checked"] = { fg = p.faint, strikethrough = true }
  groups["@markup.list.unchecked"] = { fg = p.metadata }
  link_many(groups, { "@diff.plus", "diffAdded" }, "Added")
  link_many(groups, { "@diff.delta", "diffChanged" }, "Changed")
  link_many(groups, { "@diff.minus", "diffRemoved" }, "Removed")

  -- LSP semantic tokens follow the same syntax hierarchy -----------------------
  link_many(groups, { "@lsp.type.comment" }, "Comment")
  link_many(groups, { "@lsp.type.function", "@lsp.type.method", "@lsp.type.decorator" }, "Function")
  link_many(groups, { "@lsp.type.macro" }, "Macro")
  link_many(
    groups,
    { "@lsp.type.variable", "@lsp.type.parameter", "@lsp.type.property", "@lsp.type.event" },
    "Identifier"
  )
  link_many(groups, {
    "@lsp.type.class",
    "@lsp.type.enum",
    "@lsp.type.interface",
    "@lsp.type.namespace",
    "@lsp.type.struct",
    "@lsp.type.type",
    "@lsp.type.typeParameter",
  }, "Type")
  link_many(groups, { "@lsp.type.keyword", "@lsp.type.modifier" }, "Keyword")
  link_many(groups, { "@lsp.type.operator" }, "Operator")
  link_many(groups, { "@lsp.type.string", "@lsp.type.regexp" }, "String")
  link_many(groups, { "@lsp.type.number", "@lsp.type.boolean", "@lsp.type.enumMember" }, "Constant")
  groups["@lsp.mod.deprecated"] = { fg = p.faint, strikethrough = true }
  groups["@lsp.mod.defaultLibrary"] = { fg = p.ink }
  link_many(groups, { "@lsp.typemod.function.declaration", "@lsp.typemod.method.declaration" }, "Function")
  link_many(groups, { "@lsp.typemod.variable.readonly", "@lsp.typemod.property.readonly" }, "Constant")

  -- Completion, command line, and floating controls ----------------------------
  groups.BlinkCmpMenu = { fg = p.ink, bg = p.paper }
  groups.BlinkCmpMenuBorder = { fg = p.metadata, bg = p.paper }
  groups.BlinkCmpMenuSelection = { fg = p.paper, bg = p.ink, bold = true }
  groups.BlinkCmpLabel = { fg = p.ink }
  groups.BlinkCmpLabelMatch = { fg = p.ink, bold = true }
  groups.BlinkCmpLabelDeprecated = { fg = p.faint, strikethrough = true }
  groups.BlinkCmpLabelDescription = { fg = p.faint }
  groups.BlinkCmpLabelDetail = { fg = p.faint }
  groups.BlinkCmpKind = { fg = p.metadata }
  groups.BlinkCmpSource = { fg = p.faint }
  groups.BlinkCmpGhostText = { fg = p.faint, italic = true }
  groups.BlinkCmpDoc = { fg = p.ink, bg = p.paper }
  groups.BlinkCmpDocBorder = { fg = p.metadata, bg = p.paper }
  groups.BlinkCmpDocSeparator = { fg = p.faint, bg = p.paper }
  groups.BlinkCmpDocCursorLine = { fg = p.paper, bg = p.ink }
  groups.BlinkCmpScrollBarGutter = { bg = p.paper }
  groups.BlinkCmpScrollBarThumb = { bg = p.faint }
  groups.BlinkCmpSignatureHelp = { fg = p.ink, bg = p.paper }
  groups.BlinkCmpSignatureHelpBorder = { fg = p.metadata, bg = p.paper }
  groups.BlinkCmpSignatureHelpActiveParameter = { fg = p.paper, bg = p.ink, bold = true }

  groups.NoiceCmdlinePopup = { fg = p.ink, bg = p.paper }
  groups.NoiceCmdlinePopupBorder = { fg = p.metadata, bg = p.paper }
  groups.NoiceCmdlinePopupTitle = { fg = p.ink, bg = p.paper, bold = true }
  groups.NoiceCmdlineIcon = { fg = p.metadata }
  groups.NoiceCmdlineIconCmdline = { fg = p.ink, bold = true }
  groups.NoiceCmdlineIconSearch = { fg = p.ink, bold = true }
  groups.NoicePopup = { fg = p.ink, bg = p.paper }
  groups.NoicePopupBorder = { fg = p.metadata, bg = p.paper }
  groups.NoicePopupmenu = { fg = p.ink, bg = p.paper }
  groups.NoicePopupmenuBorder = { fg = p.metadata, bg = p.paper }
  groups.NoicePopupmenuSelected = { fg = p.paper, bg = p.ink, bold = true }
  groups.NoicePopupmenuMatch = { fg = p.ink, bold = true }
  groups.NoiceConfirm = { fg = p.ink, bg = p.paper }
  groups.NoiceConfirmBorder = { fg = p.metadata, bg = p.paper }
  groups.NoiceScrollbar = { bg = p.paper }
  groups.NoiceScrollbarThumb = { bg = p.faint }
  groups.NoiceFormatProgressDone = { fg = p.success }
  groups.NoiceFormatProgressTodo = { fg = p.faint }
  groups.NoiceFormatLevelError = { fg = p.danger }
  groups.NoiceFormatLevelWarn = { fg = p.danger }
  groups.NoiceFormatLevelInfo = { fg = p.metadata }
  groups.NoiceLspProgressClient = { fg = p.ink, bold = true }
  groups.NoiceLspProgressSpinner = { fg = p.metadata }
  groups.NoiceLspProgressTitle = { fg = p.faint }

  -- Snacks uses dense, aligned source and picker zones -------------------------
  groups.SnacksNormal = { fg = p.ink, bg = p.paper }
  groups.SnacksNormalNC = { fg = p.metadata, bg = p.paper }
  groups.SnacksBackdrop = { bg = p.paper }
  groups.SnacksIndent = { fg = p.paper }
  groups.SnacksIndentScope = { fg = p.faint }
  groups.SnacksIndentChunk = { fg = p.faint }
  groups.SnacksPickerNormal = { fg = p.ink, bg = p.paper }
  groups.SnacksPickerBorder = { fg = p.metadata, bg = p.paper }
  groups.SnacksPickerTitle = { fg = p.ink, bg = p.paper, bold = true }
  groups.SnacksPickerPrompt = { fg = p.ink, bold = true }
  groups.SnacksPickerFile = { fg = p.ink }
  groups.SnacksPickerDirectory = { fg = p.metadata }
  groups.SnacksPickerDir = { fg = p.faint }
  groups.SnacksPickerPathHidden = { fg = p.faint }
  groups.SnacksPickerPathIgnored = { fg = p.faint }
  groups.SnacksPickerSelection = { fg = p.paper, bg = p.ink, bold = true }
  groups.SnacksPickerListCursorLine = { fg = p.paper, bg = p.ink, bold = true }
  groups.SnacksPickerSelected = { fg = p.paper, bg = p.ink, bold = true }
  groups.SnacksPickerFileSelected = { fg = p.paper, bg = p.ink, bold = true }
  groups.SnacksPickerDirectorySelected = { fg = p.paper, bg = p.ink, bold = true }
  groups.SnacksPickerDirSelected = { fg = p.paper, bg = p.ink }
  groups.SnacksPickerMatch = { fg = p.ink, bold = true }
  groups.SnacksPickerMatchSelected = { fg = p.paper, bg = p.ink, bold = true }
  groups.SnacksPickerSearch = { fg = p.paper, bg = p.danger, bold = true }
  groups.SnacksPickerComment = { fg = p.metadata, italic = true }
  groups.SnacksPickerDesc = { fg = p.metadata }
  groups.SnacksPickerDelim = { fg = p.faint }
  groups.SnacksPickerTotals = { fg = p.faint }
  groups.SnacksPickerGitStatusAdded = { fg = p.success }
  groups.SnacksPickerGitStatusModified = { fg = p.metadata }
  groups.SnacksPickerGitStatusDeleted = { fg = p.danger }
  groups.SnacksPickerGitStatusUnmerged = { fg = p.danger }
  groups.SnacksInputNormal = { fg = p.ink, bg = p.paper }
  groups.SnacksInputBorder = { fg = p.metadata, bg = p.paper }
  groups.SnacksInputTitle = { fg = p.ink, bg = p.paper, bold = true }
  groups.SnacksInputIcon = { fg = p.metadata }
  groups.SnacksDashboardNormal = { fg = p.ink, bg = p.paper }
  groups.SnacksDashboardHeader = { fg = p.ink, bold = true }
  groups.SnacksDashboardTitle = { fg = p.ink, bold = true }
  groups.SnacksDashboardIcon = { fg = p.metadata }
  groups.SnacksDashboardDesc = { fg = p.metadata }
  groups.SnacksDashboardKey = { fg = p.paper, bg = p.ink, bold = true }
  groups.SnacksDashboardDir = { fg = p.faint }
  groups.SnacksDashboardFooter = { fg = p.faint }
  groups.SnacksDiffAdd = { fg = p.success }
  groups.SnacksDiffDelete = { fg = p.danger }
  groups.SnacksDiffConflict = { fg = p.danger, bold = true }
  groups.SnacksDiffContext = { fg = p.metadata }
  groups.SnacksDiffHeader = { fg = p.ink, bold = true }
  groups.SnacksDiffLabel = { fg = p.faint }

  for _, level in ipairs({ "Debug", "Trace" }) do
    groups["SnacksNotifierBorder" .. level] = { fg = p.faint, bg = p.paper }
    groups["SnacksNotifierTitle" .. level] = { fg = p.metadata, bg = p.paper }
    groups["SnacksNotifierIcon" .. level] = { fg = p.metadata, bg = p.paper }
  end
  for _, level in ipairs({ "Error", "Warn" }) do
    groups["SnacksNotifierBorder" .. level] = { fg = p.danger, bg = p.paper }
    groups["SnacksNotifierTitle" .. level] = { fg = p.danger, bg = p.paper, bold = true }
    groups["SnacksNotifierIcon" .. level] = { fg = p.danger, bg = p.paper }
  end
  groups.SnacksNotifierBorderInfo = { fg = p.metadata, bg = p.paper }
  groups.SnacksNotifierTitleInfo = { fg = p.ink, bg = p.paper, bold = true }
  groups.SnacksNotifierIconInfo = { fg = p.ink, bg = p.paper }

  -- Navigation and utility panels ---------------------------------------------
  groups.WhichKeyNormal = { fg = p.ink, bg = p.paper }
  groups.WhichKeyBorder = { fg = p.metadata, bg = p.paper }
  groups.WhichKeyTitle = { fg = p.ink, bg = p.paper, bold = true }
  groups.WhichKey = { fg = p.ink, bold = true }
  groups.WhichKeyGroup = { fg = p.ink, bold = true }
  groups.WhichKeyDesc = { fg = p.metadata }
  groups.WhichKeySeparator = { fg = p.faint }
  groups.WhichKeyValue = { fg = p.faint }
  groups.WhichKeyIcon = { fg = p.metadata }
  for _, suffix in ipairs({ "Azure", "Blue", "Cyan", "Green", "Grey", "Orange", "Purple", "Red", "Yellow" }) do
    groups["WhichKeyIcon" .. suffix] = { fg = p.metadata }
    groups["WhichKeyColor" .. suffix] = { fg = p.metadata }
  end

  groups.LazyNormal = { fg = p.ink, bg = p.paper }
  groups.LazyBackdrop = { bg = p.paper }
  groups.LazyButton = { fg = p.metadata, bg = p.paper }
  groups.LazyButtonActive = { fg = p.paper, bg = p.ink, bold = true }
  groups.LazyH1 = { fg = p.paper, bg = p.ink, bold = true }
  groups.LazyH2 = { fg = p.ink, bold = true }
  groups.LazyComment = { fg = p.metadata, italic = true }
  groups.LazyDimmed = { fg = p.faint }
  groups.LazyReasonPlugin = { fg = p.faint }
  groups.LazyProgressDone = { fg = p.success }
  groups.LazyProgressTodo = { fg = p.faint }

  groups.MasonNormal = { fg = p.ink, bg = p.paper }
  groups.MasonHeader = { fg = p.paper, bg = p.ink, bold = true }
  groups.MasonHeaderSecondary = { fg = p.ink, bg = p.paper, bold = true }
  groups.MasonHeading = { fg = p.ink, bold = true }
  groups.MasonHighlight = { fg = p.ink }
  groups.MasonHighlightBlock = { fg = p.paper, bg = p.ink }
  groups.MasonHighlightBlockBold = { fg = p.paper, bg = p.ink, bold = true }
  groups.MasonMuted = { fg = p.faint }
  groups.MasonMutedBlock = { fg = p.metadata, bg = p.paper }
  groups.MasonError = { fg = p.danger }
  groups.MasonWarning = { fg = p.danger }

  groups.TroubleNormal = { fg = p.ink, bg = p.paper }
  groups.TroubleNormalNC = { fg = p.metadata, bg = p.paper }
  groups.TroubleText = { fg = p.ink }
  groups.TroubleBasename = { fg = p.ink, bold = true }
  groups.TroubleFilename = { fg = p.metadata }
  groups.TroubleDirectory = { fg = p.faint }
  groups.TroubleSource = { fg = p.faint }
  groups.TroubleCode = { fg = p.metadata }
  groups.TroubleCount = { fg = p.paper, bg = p.ink, bold = true }
  groups.TroubleIndent = { fg = p.faint }
  groups.TroublePreview = { fg = p.paper, bg = p.ink }

  groups.AerialNormal = { fg = p.ink, bg = p.paper }
  groups.AerialNormalFloat = { fg = p.ink, bg = p.paper }
  groups.AerialGuide = { fg = p.faint }
  groups.AerialLine = { fg = p.paper, bg = p.ink, bold = true }
  groups.AerialLineNC = { fg = p.metadata, bg = p.paper }
  groups.AerialFunction = { fg = p.ink, bold = true }
  groups.AerialPrivate = { fg = p.faint }
  groups.AerialProtected = { fg = p.metadata }

  -- Test, debug, and task state -------------------------------------------------
  groups.NeotestPassed = { fg = p.success }
  groups.NeotestFailed = { fg = p.danger }
  groups.NeotestRunning = { fg = p.metadata }
  groups.NeotestSkipped = { fg = p.faint }
  groups.NeotestUnknown = { fg = p.faint }
  groups.NeotestFocused = { fg = p.paper, bg = p.ink, bold = true }
  groups.NeotestMarked = { fg = p.ink, bold = true }
  groups.NeotestTarget = { fg = p.ink, bold = true }
  groups.NeotestFile = { fg = p.ink }
  groups.NeotestDir = { fg = p.metadata }
  groups.NeotestNamespace = { fg = p.metadata }
  groups.NeotestTest = { fg = p.ink }
  groups.NeotestIndent = { fg = p.faint }
  groups.NeotestBorder = { fg = p.metadata, bg = p.paper }

  groups.DapBreakpoint = { fg = p.danger }
  groups.DapBreakpointCondition = { fg = p.danger }
  groups.DapBreakpointRejected = { fg = p.danger }
  groups.DapLogPoint = { fg = p.metadata }
  groups.DapStopped = { fg = p.paper, bg = p.ink, bold = true }
  groups.DapStoppedLine = { fg = p.paper, bg = p.ink }
  groups.DapUINormal = { fg = p.ink, bg = p.paper }
  groups.DapUIFloatNormal = { fg = p.ink, bg = p.paper }
  groups.DapUIFloatBorder = { fg = p.metadata, bg = p.paper }
  groups.DapUIScope = { fg = p.ink, bold = true }
  groups.DapUIType = { fg = p.faint }
  groups.DapUIValue = { fg = p.ink }
  groups.DapUIVariable = { fg = p.ink }
  groups.DapUIModifiedValue = { fg = p.ink, bold = true }
  groups.DapUIWatchesError = { fg = p.danger }
  groups.DapUIWatchesEmpty = { fg = p.faint }
  groups.DapUIStoppedThread = { fg = p.paper, bg = p.ink, bold = true }
  groups.DapUIUnavailable = { fg = p.faint }
  groups.DapUIStop = { fg = p.danger }

  groups.TodoFgFIX = { fg = p.danger, bold = true }
  groups.TodoFgWARN = { fg = p.danger, bold = true }
  groups.TodoFgTODO = { fg = p.ink, bold = true }
  groups.TodoFgHACK = { fg = p.metadata, bold = true }
  groups.TodoFgNOTE = { fg = p.metadata, bold = true }
  groups.TodoBgFIX = { fg = p.paper, bg = p.danger, bold = true }
  groups.TodoBgWARN = { fg = p.paper, bg = p.danger, bold = true }
  groups.TodoBgTODO = { fg = p.paper, bg = p.ink, bold = true }
  groups.TodoSignFIX = { fg = p.danger }
  groups.TodoSignWARN = { fg = p.danger }
  groups.TodoSignTODO = { fg = p.ink }
  groups.TodoSignHACK = { fg = p.metadata }
  groups.TodoSignNOTE = { fg = p.metadata }

  -- Git and editing actions -----------------------------------------------------
  groups.GitSignsAdd = { fg = p.success }
  groups.GitSignsChange = { fg = p.metadata }
  groups.GitSignsDelete = { fg = p.danger }
  groups.GitSignsTopdelete = { fg = p.danger }
  groups.GitSignsChangedelete = { fg = p.danger }
  groups.GitSignsUntracked = { fg = p.success }
  groups.GitSignsCurrentLineBlame = { fg = p.faint, italic = true }
  groups.GitSignsAddInline = { fg = p.success, bg = p.paper }
  groups.GitSignsDeleteInline = { fg = p.paper, bg = p.danger }
  groups.GitSignsChangeInline = { fg = p.ink, bg = p.faint }
  groups.GitConflictCurrent = { fg = p.ink, bg = p.paper }
  groups.GitConflictIncoming = { fg = p.metadata, bg = p.paper }
  groups.GitConflictAncestor = { fg = p.faint, bg = p.paper }

  groups.FlashBackdrop = { fg = p.faint }
  groups.FlashMatch = { fg = p.metadata, bold = true }
  groups.FlashCurrent = { fg = p.paper, bg = p.ink, bold = true }
  groups.FlashLabel = { fg = p.paper, bg = p.danger, bold = true }
  groups.YankyPut = { fg = p.paper, bg = p.ink }
  groups.YankyYanked = { fg = p.ink, underline = true, sp = p.ink }
  groups.MiniHipatternsFixme = { fg = p.paper, bg = p.danger, bold = true }
  groups.MiniHipatternsHack = { fg = p.danger, bold = true }
  groups.MiniHipatternsTodo = { fg = p.paper, bg = p.ink, bold = true }
  groups.MiniHipatternsNote = { fg = p.metadata, bold = true }

  -- Markdown rendering remains a bounded source surface, not a soft card -------
  groups.RenderMarkdownH1 = { fg = p.ink, bold = true }
  groups.RenderMarkdownH2 = { fg = p.ink, bold = true }
  groups.RenderMarkdownH3 = { fg = p.metadata, bold = true }
  groups.RenderMarkdownH4 = { fg = p.metadata }
  groups.RenderMarkdownH5 = { fg = p.faint }
  groups.RenderMarkdownH6 = { fg = p.faint }
  for level = 1, 6 do
    groups["RenderMarkdownH" .. level .. "Bg"] = { fg = p.ink, bg = p.paper }
  end
  groups.RenderMarkdownCode = { fg = p.ink, bg = p.paper }
  groups.RenderMarkdownCodeInline = { fg = p.ink, bg = p.paper }
  groups.RenderMarkdownCodeBorder = { fg = p.faint, bg = p.paper }
  groups.RenderMarkdownCodeInfo = { fg = p.metadata, bg = p.paper }
  groups.RenderMarkdownQuote = { fg = p.metadata, italic = true }
  for level = 1, 6 do
    groups["RenderMarkdownQuote" .. level] = { fg = level <= 2 and p.metadata or p.faint, italic = true }
  end
  groups.RenderMarkdownLink = { fg = p.ink }
  groups.RenderMarkdownWikiLink = { fg = p.ink }
  groups.RenderMarkdownLinkTitle = { fg = p.metadata }
  groups.RenderMarkdownBullet = { fg = p.faint }
  groups.RenderMarkdownDash = { fg = p.faint }
  groups.RenderMarkdownUnchecked = { fg = p.metadata }
  groups.RenderMarkdownChecked = { fg = p.faint, strikethrough = true }
  groups.RenderMarkdownTodo = { fg = p.ink, bold = true }
  groups.RenderMarkdownSuccess = { fg = p.success }
  groups.RenderMarkdownInfo = { fg = p.metadata }
  groups.RenderMarkdownHint = { fg = p.faint }
  groups.RenderMarkdownWarn = { fg = p.danger }
  groups.RenderMarkdownError = { fg = p.danger }
  groups.RenderMarkdownTableHead = { fg = p.metadata, bold = true }
  groups.RenderMarkdownTableRow = { fg = p.faint }
  groups.RenderMarkdownTableFill = { fg = p.faint }
  groups.RenderMarkdownInlineHighlight = { fg = p.paper, bg = p.ink }
  groups.RenderMarkdownMath = { fg = p.ink }
  groups.RenderMarkdownHtmlComment = { fg = p.metadata, italic = true }

  -- Context rails ---------------------------------------------------------------
  groups.TreesitterContext = { fg = p.metadata, bg = p.paper }
  groups.TreesitterContextLineNumber = { fg = p.faint, bg = p.paper }
  groups.TreesitterContextBottom = { underline = true, sp = p.faint }
  groups.TreesitterContextSeparator = { fg = p.faint }

  return groups
end

function M.apply_dynamic(p)
  local ok, existing = pcall(vim.api.nvim_get_hl, 0, {})
  if not ok then
    return
  end

  for name in pairs(existing) do
    if name:match("^SnacksPickerIconSelected") then
      vim.api.nvim_set_hl(0, name, { fg = p.paper, bg = p.ink, bold = true })
    elseif name:match("^DevIcon") or name:match("^MiniIcons") then
      vim.api.nvim_set_hl(0, name, { fg = p.metadata })
    elseif name:match("^lualine_") then
      -- Persistent chrome is scaffolding, not the editor's focal surface.
      local spec = { fg = p.faint, bg = p.paper }

      if name:match("diff_removed") then
        spec.fg = p.danger
      elseif name:match("diff_added") then
        spec.fg = p.success
      elseif name:match("diff_modified") then
        spec.fg = p.metadata
      elseif name:match("^lualine_z_command") or name:match("^lualine_z_replace") then
        spec = { fg = p.danger, bg = p.paper, bold = true }
      elseif name:match("^lualine_z_insert") or name:match("^lualine_z_visual") then
        spec = { fg = p.metadata, bg = p.paper }
      end

      vim.api.nvim_set_hl(0, name, spec)
    end
  end
end

return M
