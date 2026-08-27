-- Configuration options (可以写在你的 init.lua 中)
-- vim.g.mariana_italic         = false
-- vim.g.mariana_transparent    = true
-- vim.g.mariana_dim_cursorline = true
-- vim.g.mariana_dim_inactive   = true

local function opt(name, default)
  local v = vim.g[name]
  if v == nil then
    return default
  end
  return not (v == false or v == 0)
end

local cfg = {
  italic = opt('mariana_italic', false),
  transparent = opt('mariana_transparent', false),
  dim_cursorline = opt('mariana_dim_cursorline', false),
  dim_inactive = opt('mariana_dim_inactive', false),
}

-- 预计算的纯静态色板 (移除了冗长的 hsl 和 rgba 混合计算)
local colors = {
  black = '#000000',
  blue = '#6699cc',
  blue_vib = '#5c99d6', -- blue-vibrant / accent
  blue2 = '#4d5c6b', -- 半透明选区/当前行色
  blue3 = '#303841', -- background
  blue4 = '#65737e', -- selection_border
  blue5 = '#5fb3b3', -- cyan / active_guide
  blue6 = '#a6acb9', -- comment / separator
  green = '#99c794',
  grey = '#333333', -- find_highlight_foreground
  orange = '#fac863', -- caret / number / parameter
  orange2 = '#f59335', -- invalid.deprecated
  orange3 = '#f9ae57', -- find_highlight
  pink = '#c594c5',
  red = '#ec5f67',
  red2 = '#f97b58', -- keyword.operator
  white = '#ffffff', -- punctuation.section
  white2 = '#f7f7f7', -- invalid 前景
  white3 = '#d8dee9', -- foreground

  -- 合成背景衍生色
  stack_guide = '#47757a',
  raw_bg = '#3f4b57',
  raw_bg_inline = '#44515f',
  diff_del = '#493c44',
  diff_del_char = '#63424a',
  diff_ins = '#374b53',
  diff_ins_char = '#425f69',
  cursorline_dim = '#3e4953',

  -- UI Chrome
  ui_bar = '#293038',
  ui_deep = '#21262b',
  ui_light = '#3d4651',
  ui_dim = '#272d34',
  guide = '#424d56',
}

-- 初始化
vim.cmd('highlight clear')
if vim.fn.exists('syntax_on') == 1 then
  vim.cmd('syntax reset')
end
vim.o.background = 'dark'
vim.g.colors_name = 'mariana'

local function setcolor()
  local c = colors
  local it = cfg.italic
  local bg = cfg.transparent and 'NONE' or c.blue3
  local bg_float = cfg.transparent and 'NONE' or c.ui_bar
  local cursorline = cfg.dim_cursorline and c.cursorline_dim or c.blue2

  local groups = {
    -- ─── Base Editor ─────────────────────────────────────────────────────
    Normal = { fg = c.white3, bg = bg },
    NormalNC = { fg = c.white3, bg = cfg.dim_inactive and c.ui_dim or bg },
    NormalFloat = { fg = c.white3, bg = bg_float },
    FloatBorder = { fg = c.blue4, bg = bg_float },
    FloatTitle = { fg = c.blue_vib, bg = bg_float, bold = true },

    Cursor = { fg = c.blue3, bg = c.orange },
    lCursor = { link = 'Cursor' },
    CursorIM = { link = 'Cursor' },
    TermCursor = { link = 'Cursor' },

    CursorLine = { bg = cursorline },
    CursorColumn = { bg = cursorline },
    ColorColumn = { bg = c.ui_light },
    CursorLineNr = { fg = c.white3, bold = true },
    LineNr = { fg = c.blue4 },
    LineNrAbove = { fg = c.blue4 },
    LineNrBelow = { fg = c.blue4 },

    SignColumn = { fg = c.blue4, bg = bg },
    FoldColumn = { fg = c.blue4, bg = bg },
    Folded = { fg = c.blue6, bg = c.ui_light },
    WinSeparator = { fg = c.ui_deep, bg = bg },
    VertSplit = { link = 'WinSeparator' },

    NonText = { fg = '#4a545f' },
    Whitespace = { fg = '#4a545f' },
    SpecialKey = { fg = '#4a545f' },
    Conceal = { fg = c.blue4 },
    EndOfBuffer = { fg = cfg.transparent and c.blue3 or bg },
    MatchParen = { fg = c.orange, underline = true },

    Visual = { bg = c.blue2 },
    VisualNOS = { bg = c.blue2 },
    Search = { fg = c.grey, bg = c.orange3 },
    IncSearch = { fg = c.grey, bg = c.orange3, bold = true },
    CurSearch = { link = 'IncSearch' },
    Substitute = { fg = c.grey, bg = c.red2 },

    Directory = { fg = c.blue },
    Title = { fg = c.blue_vib, bold = true },
    ErrorMsg = { fg = c.red, bold = true },
    WarningMsg = { fg = c.orange },
    MoreMsg = { fg = c.green },
    Question = { fg = c.blue5 },
    ModeMsg = { fg = c.white3, bold = true },
    MsgArea = { fg = c.white3 },
    MsgSeparator = { fg = c.ui_deep, bg = bg },
    Underlined = { underline = true },
    Ignore = { fg = c.blue4 },
    Error = { fg = c.white2, bg = c.red },
    Todo = { fg = c.grey, bg = c.orange3, bold = true },

    SpellBad = { sp = c.red, undercurl = true },
    SpellCap = { sp = c.orange, undercurl = true },
    SpellLocal = { sp = c.blue5, undercurl = true },
    SpellRare = { sp = c.pink, undercurl = true },

    -- ─── UI Components ───────────────────────────────────────────────────
    StatusLine = { fg = c.blue6, bg = bg },
    StatusLineNC = { fg = c.blue4, bg = bg },
    TabLine = { fg = c.blue4, bg = c.ui_deep },
    TabLineFill = { bg = c.ui_deep },
    TabLineSel = { fg = c.white3, bg = c.blue3, bold = true },
    WinBar = { fg = c.blue6, bg = bg },
    WinBarNC = { fg = c.blue4, bg = bg },

    Pmenu = { fg = c.white3, bg = c.ui_bar },
    PmenuSel = { fg = c.white3, bg = c.blue2, bold = true },
    PmenuKind = { fg = c.blue5, bg = c.ui_bar },
    PmenuKindSel = { fg = c.blue5, bg = c.blue2 },
    PmenuExtra = { fg = c.blue4, bg = c.ui_bar },
    PmenuExtraSel = { fg = c.blue6, bg = c.blue2 },
    PmenuSbar = { bg = c.ui_deep },
    PmenuThumb = { bg = c.blue4 },
    WildMenu = { link = 'PmenuSel' },

    -- ─── Syntax Base ─────────────────────────────────────────────────────
    Comment = { fg = c.blue6 },
    Constant = { fg = c.white3 },
    String = { fg = c.green },
    Character = { fg = c.green },
    Number = { fg = c.orange },
    Boolean = { fg = c.red, italic = it },
    Float = { fg = c.orange },
    Identifier = { fg = c.white3 },
    Function = { fg = c.blue5 },
    Statement = { fg = c.pink },
    Conditional = { fg = c.pink },
    Repeat = { fg = c.pink },
    Label = { fg = c.pink },
    Operator = { fg = c.red2 },
    Keyword = { fg = c.pink },
    Exception = { fg = c.pink },
    PreProc = { fg = c.pink },
    Include = { fg = c.pink },
    Define = { fg = c.pink },
    Macro = { fg = c.blue, italic = it },
    PreCondit = { fg = c.pink },
    Type = { fg = c.orange },
    StorageClass = { fg = c.red },
    Structure = { fg = c.pink, italic = it },
    Typedef = { fg = c.pink, italic = it },
    Special = { fg = c.blue5 },
    SpecialChar = { fg = c.pink },
    Tag = { fg = c.red },
    Delimiter = { fg = c.blue6 },
    SpecialComment = { fg = c.blue6, bold = true },
    Debug = { fg = c.red },

    -- ─── Treesitter ──────────────────────────────────────────────────────
    ['@variable'] = { fg = c.white3 },
    ['@variable.builtin'] = { fg = c.red, italic = it },
    ['@variable.parameter'] = { fg = c.white3 },
    ['@variable.parameter.builtin'] = { fg = c.orange },
    ['@variable.member'] = { fg = c.white3 },

    ['@constant'] = { fg = c.white3 },
    ['@constant.builtin'] = { fg = c.red, italic = it },
    ['@constant.macro'] = { fg = c.pink },

    ['@module'] = { fg = c.orange },
    ['@module.builtin'] = { fg = c.blue, italic = it },
    ['@label'] = { fg = c.white3 },

    ['@string'] = { fg = c.green },
    ['@string.documentation'] = { fg = c.green },
    ['@string.regexp'] = { fg = c.green },
    ['@string.escape'] = { fg = c.pink },
    ['@string.special'] = { fg = c.pink },
    ['@string.special.path'] = { fg = c.green },
    ['@string.special.symbol'] = { fg = c.pink },
    ['@string.special.url'] = { fg = c.blue },
    ['@character'] = { fg = c.green },
    ['@character.special'] = { fg = c.pink },

    ['@boolean'] = { fg = c.red, italic = it },
    ['@number'] = { fg = c.orange },
    ['@number.float'] = { fg = c.orange },

    ['@type'] = { fg = c.orange },
    ['@type.builtin'] = { fg = c.pink, italic = it },
    ['@type.definition'] = { fg = c.orange },
    ['@attribute'] = { fg = c.blue },
    ['@attribute.builtin'] = { fg = c.blue, italic = it },
    ['@property'] = { fg = c.white3 },

    ['@function'] = { fg = c.blue5 },
    ['@function.call'] = { fg = c.blue },
    ['@function.method'] = { fg = c.blue5 },
    ['@function.method.call'] = { fg = c.blue },
    ['@function.builtin'] = { fg = c.blue, italic = it },
    ['@function.macro'] = { fg = c.blue, italic = it },
    ['@constructor'] = { fg = c.orange },
    ['@operator'] = { fg = c.red2 },

    ['@keyword'] = { fg = c.pink },
    ['@keyword.coroutine'] = { fg = c.pink },
    ['@keyword.function'] = { fg = c.pink, italic = it },
    ['@keyword.operator'] = { fg = c.pink },
    ['@keyword.import'] = { fg = c.pink },
    ['@keyword.type'] = { fg = c.pink, italic = it },
    ['@keyword.modifier'] = { fg = c.red },
    ['@keyword.repeat'] = { fg = c.pink },
    ['@keyword.return'] = { fg = c.pink },
    ['@keyword.debug'] = { fg = c.pink },
    ['@keyword.exception'] = { fg = c.pink },
    ['@keyword.conditional'] = { fg = c.pink },
    ['@keyword.conditional.ternary'] = { fg = c.red2 },
    ['@keyword.directive'] = { fg = c.pink },
    ['@keyword.directive.define'] = { fg = c.pink },

    ['@punctuation.delimiter'] = { fg = c.blue6 },
    ['@punctuation.bracket'] = { fg = c.white },
    ['@punctuation.special'] = { fg = c.blue5 },

    ['@comment'] = { fg = c.blue6 },
    ['@comment.documentation'] = { fg = c.blue6 },
    ['@comment.error'] = { fg = c.white2, bg = c.red, bold = true },
    ['@comment.warning'] = { fg = c.grey, bg = c.orange2, bold = true },
    ['@comment.todo'] = { fg = c.grey, bg = c.orange3, bold = true },
    ['@comment.note'] = { fg = c.grey, bg = c.blue5, bold = true },

    ['@markup.strong'] = { bold = true },
    ['@markup.italic'] = { italic = true },
    ['@markup.strikethrough'] = { strikethrough = true },
    ['@markup.underline'] = { underline = true },
    ['@markup.heading'] = { fg = c.white3, bold = true },
    ['@markup.heading.1.marker'] = { fg = c.red },
    ['@markup.heading.2.marker'] = { fg = c.red2 },
    ['@markup.heading.3.marker'] = { fg = c.red2 },
    ['@markup.heading.4.marker'] = { fg = c.red2 },
    ['@markup.heading.5.marker'] = { fg = c.red2 },
    ['@markup.heading.6.marker'] = { fg = c.red2 },
    ['@markup.quote'] = { fg = c.orange },
    ['@markup.math'] = { fg = c.blue5 },
    ['@markup.link'] = { fg = c.blue },
    ['@markup.link.label'] = { fg = c.blue },
    ['@markup.link.url'] = { fg = c.blue, underline = true },
    ['@markup.list'] = { fg = c.orange },
    ['@markup.list.checked'] = { fg = c.green },
    ['@markup.list.unchecked'] = { fg = c.blue6 },

    ['@tag'] = { fg = c.red },
    ['@tag.builtin'] = { fg = c.red },
    ['@tag.attribute'] = { fg = c.pink },
    ['@tag.delimiter'] = { fg = c.blue5 },

    -- 语言特例
    ['@property.yaml'] = { fg = c.blue5 },
    ['@field.yaml'] = { fg = c.blue5 },
    ['@string.yaml'] = { fg = c.white3 },
    ['@property.json'] = { fg = c.green },
    ['@property.jsonc'] = { fg = c.green },
    ['@property.css'] = { fg = c.white3 },
    ['@property.scss'] = { fg = c.white3 },
    ['@type.css'] = { fg = c.red },
    ['@variable.parameter.bash'] = { fg = c.white3 },
    ['@variable.parameter.vim'] = { fg = c.white3 },
    ['@annotation'] = { fg = c.white3 },

    -- ─── LSP Semantic Highlights ─────────────────────────────────────────
    ['@lsp.type.class'] = { fg = c.orange },
    ['@lsp.type.comment'] = {},
    ['@lsp.type.decorator'] = { fg = c.blue },
    ['@lsp.type.enum'] = { fg = c.orange },
    ['@lsp.type.enumMember'] = { fg = c.pink },
    ['@lsp.type.event'] = { fg = c.orange },
    ['@lsp.type.function'] = { fg = c.blue5 },
    ['@lsp.type.interface'] = { fg = c.orange },
    ['@lsp.type.keyword'] = { fg = c.pink },
    ['@lsp.type.macro'] = { fg = c.blue, italic = it },
    ['@lsp.type.method'] = { fg = c.blue5 },
    ['@lsp.type.modifier'] = { fg = c.red },
    ['@lsp.type.namespace'] = { fg = c.orange },
    ['@lsp.type.number'] = { fg = c.orange },
    ['@lsp.type.operator'] = { fg = c.red2 },
    ['@lsp.type.parameter'] = { fg = c.orange },
    ['@lsp.type.property'] = { fg = c.white3 },
    ['@lsp.type.regexp'] = { fg = c.green },
    ['@lsp.type.string'] = { fg = c.green },
    ['@lsp.type.struct'] = { fg = c.orange },
    ['@lsp.type.type'] = { fg = c.orange },
    ['@lsp.type.typeParameter'] = { fg = c.orange },
    ['@lsp.type.variable'] = {},

    ['@lsp.mod.deprecated'] = { strikethrough = true },
    ['@lsp.typemod.function.defaultLibrary'] = { fg = c.blue, italic = it },
    ['@lsp.typemod.method.defaultLibrary'] = { fg = c.blue, italic = it },
    ['@lsp.typemod.variable.defaultLibrary'] = { fg = c.red, italic = it },
    ['@lsp.typemod.class.defaultLibrary'] = { fg = c.blue, italic = it },
    ['@lsp.typemod.variable.readonly'] = { fg = c.pink },
    ['@lsp.typemod.variable.global'] = { fg = c.pink },

    -- ─── Diagnostics ─────────────────────────────────────────────────────
    DiagnosticError = { fg = c.red },
    DiagnosticWarn = { fg = c.orange },
    DiagnosticInfo = { fg = c.blue },
    DiagnosticHint = { fg = c.blue5 },
    DiagnosticOk = { fg = c.green },

    DiagnosticVirtualTextError = { fg = c.red, bg = 'NONE' },
    DiagnosticVirtualTextWarn = { fg = c.orange, bg = 'NONE' },
    DiagnosticVirtualTextInfo = { fg = c.blue, bg = 'NONE' },
    DiagnosticVirtualTextHint = { fg = c.blue5, bg = 'NONE' },
    DiagnosticVirtualTextOk = { fg = c.green, bg = 'NONE' },

    DiagnosticUnderlineError = { sp = c.red, undercurl = true },
    DiagnosticUnderlineWarn = { sp = c.orange, undercurl = true },
    DiagnosticUnderlineInfo = { sp = c.blue, undercurl = true },
    DiagnosticUnderlineHint = { sp = c.blue5, undercurl = true },
    DiagnosticUnderlineOk = { sp = c.green, undercurl = true },

    DiagnosticUnnecessary = { fg = c.blue4 },
    DiagnosticDeprecated = { sp = c.blue4, strikethrough = true },
    DiagnosticFloatingError = { fg = c.red, bg = bg_float },
    DiagnosticFloatingWarn = { fg = c.orange, bg = bg_float },
    DiagnosticFloatingInfo = { fg = c.blue, bg = bg_float },
    DiagnosticFloatingHint = { fg = c.blue5, bg = bg_float },
    DiagnosticSignError = { fg = c.red, bg = bg },
    DiagnosticSignWarn = { fg = c.orange, bg = bg },
    DiagnosticSignInfo = { fg = c.blue, bg = bg },
    DiagnosticSignHint = { fg = c.blue5, bg = bg },

    -- Rainbow delimeters
    RainbowBracket1 = { fg = c.pink, bold = true },
    RainbowBracket2 = { fg = c.blue, bold = true },
    RainbowBracket3 = { fg = c.blue5, bold = true },
    RainbowBracket4 = { fg = c.green, bold = true },
    RainbowBracket5 = { fg = c.orange, bold = true },
    RainbowBracket6 = { fg = c.red, bold = true },

    -- ─── Plugins ─────────────────────────────────────────────────────────
    -- Diff / Gitsigns
    DiffAdd = { bg = c.diff_ins },
    DiffChange = { bg = c.diff_ins },
    DiffDelete = { fg = c.red, bg = c.diff_del },
    DiffText = { bg = c.diff_ins_char },
    diffAdded = { fg = c.green },
    diffRemoved = { fg = c.red },
    diffChanged = { fg = c.orange },
    diffFile = { fg = c.pink },
    diffLine = { fg = c.pink },
    diffIndexLine = { fg = c.pink },
    ['@diff.plus'] = { fg = c.green },
    ['@diff.minus'] = { fg = c.red },
    ['@diff.delta'] = { fg = c.orange },

    GitSignsAdd = { fg = c.green, bg = bg },
    GitSignsChange = { fg = c.orange, bg = bg },
    GitSignsDelete = { fg = c.red, bg = bg },
    GitSignsAddInline = { bg = c.diff_ins_char },
    GitSignsChangeInline = { bg = c.diff_ins_char },
    GitSignsDeleteInline = { bg = c.diff_del_char },
    GitSignsCurrentLineBlame = { fg = c.blue4 },

    -- LSP / Plugins Base
    LspReferenceText = { bg = c.ui_light },
    LspReferenceRead = { bg = c.ui_light },
    LspReferenceWrite = { bg = c.ui_light, underline = true },
    LspInlayHint = { fg = c.blue4, bg = c.cursorline_dim },
    LspSignatureActiveParameter = { fg = c.orange, bold = true },
    LspCodeLens = { fg = c.blue4 },
    LspInfoBorder = { fg = c.blue4, bg = bg_float },
    QuickFixLine = { bg = c.blue2 },

    -- Indent
    IblIndent = { fg = c.guide },
    IblScope = { fg = c.blue5 },
    IblWhitespace = { fg = c.guide },
    IndentBlanklineChar = { fg = c.guide },
    IndentBlanklineContextChar = { fg = c.blue5 },
    MiniIndentscopeSymbol = { fg = c.blue5 },
    IndentLine = { link = 'Comment' },
    IndentLineCurrent = { fg = c.blue5 },

    -- Telescope
    TelescopeNormal = { fg = c.white3, bg = c.ui_bar },
    TelescopeBorder = { fg = c.ui_deep, bg = c.ui_bar },
    TelescopeTitle = { fg = c.blue3, bg = c.blue_vib, bold = true },
    TelescopePromptNormal = { fg = c.white3, bg = c.ui_light },
    TelescopePromptBorder = { fg = c.ui_light, bg = c.ui_light },
    TelescopePromptTitle = { fg = c.grey, bg = c.orange, bold = true },
    TelescopePromptPrefix = { fg = c.orange },
    TelescopePromptCounter = { fg = c.blue4 },
    TelescopePreviewTitle = { fg = c.blue3, bg = c.blue5, bold = true },
    TelescopeResultsTitle = { fg = c.ui_bar, bg = c.ui_bar },
    TelescopeSelection = { fg = c.white3, bg = c.blue2 },
    TelescopeSelectionCaret = { fg = c.orange, bg = c.blue2 },
    TelescopeMultiSelection = { fg = c.pink },
    TelescopeMatching = { fg = c.grey, bg = c.orange3 },

    -- nvim-cmp / Blink
    CmpItemAbbr = { fg = c.white3 },
    CmpItemAbbrDeprecated = { fg = c.blue4, strikethrough = true },
    CmpItemAbbrMatch = { fg = c.orange3, bold = true },
    CmpItemAbbrMatchFuzzy = { fg = c.orange3 },
    CmpItemMenu = { fg = c.blue4 },
    CmpItemKindText = { fg = c.white3 },
    CmpItemKindMethod = { fg = c.blue5 },
    CmpItemKindFunction = { fg = c.blue5 },
    CmpItemKindConstructor = { fg = c.orange },
    CmpItemKindField = { fg = c.red },
    CmpItemKindVariable = { fg = c.white3 },
    CmpItemKindClass = { fg = c.orange },
    CmpItemKindInterface = { fg = c.orange },
    CmpItemKindModule = { fg = c.orange },
    CmpItemKindProperty = { fg = c.red },
    CmpItemKindUnit = { fg = c.orange },
    CmpItemKindValue = { fg = c.orange },
    CmpItemKindEnum = { fg = c.orange },
    CmpItemKindKeyword = { fg = c.pink },
    CmpItemKindSnippet = { fg = c.green },
    CmpItemKindColor = { fg = c.red2 },
    CmpItemKindFile = { fg = c.blue5 },
    CmpItemKindReference = { fg = c.red },
    CmpItemKindFolder = { fg = c.blue5 },
    CmpItemKindEnumMember = { fg = c.pink },
    CmpItemKindConstant = { fg = c.pink },
    CmpItemKindStruct = { fg = c.orange },
    CmpItemKindEvent = { fg = c.orange },
    CmpItemKindOperator = { fg = c.red2 },
    CmpItemKindTypeParameter = { fg = c.orange },

    BlinkCmpMenu = { link = 'Pmenu' },
    BlinkCmpMenuBorder = { link = 'FloatBorder' },
    BlinkCmpMenuSelection = { link = 'PmenuSel' },
    BlinkCmpLabelMatch = { fg = c.orange3, bold = true },
    BlinkCmpLabelDeprecated = { fg = c.blue4, strikethrough = true },
    BlinkCmpKind = { fg = c.blue5 },

    -- File Trees
    NvimTreeNormal = { fg = c.blue6, bg = c.ui_bar },
    NvimTreeNormalNC = { fg = c.blue6, bg = c.ui_bar },
    NvimTreeWinSeparator = { fg = c.ui_deep, bg = c.ui_bar },
    NvimTreeRootFolder = { fg = c.pink, bold = true },
    NvimTreeFolderName = { fg = c.blue6 },
    NvimTreeOpenedFolderName = { fg = c.white3, bold = true },
    NvimTreeEmptyFolderName = { fg = c.blue4 },
    NvimTreeFolderIcon = { fg = c.blue6 },
    NvimTreeIndentMarker = { fg = c.guide },
    NvimTreeSpecialFile = { fg = c.orange },
    NvimTreeExecFile = { fg = c.green },
    NvimTreeImageFile = { fg = c.pink },
    NvimTreeSymlink = { fg = c.blue5 },
    NvimTreeGitDirty = { fg = c.orange },
    NvimTreeGitNew = { fg = c.green },
    NvimTreeGitDeleted = { fg = c.red },
    NvimTreeCursorLine = { bg = c.blue2 },

    NeoTreeNormal = { fg = c.blue6, bg = c.ui_bar },
    NeoTreeNormalNC = { fg = c.blue6, bg = c.ui_bar },
    NeoTreeDirectoryName = { fg = c.blue6 },
    NeoTreeDirectoryIcon = { fg = c.blue6 },
    NeoTreeRootName = { fg = c.pink, bold = true },
    NeoTreeIndentMarker = { fg = c.guide },
    NeoTreeGitAdded = { fg = c.green },
    NeoTreeGitModified = { fg = c.orange },
    NeoTreeGitDeleted = { fg = c.red },
    NeoTreeCursorLine = { bg = c.blue2 },

    -- WhichKey & Notify
    WhichKey = { fg = c.pink },
    WhichKeyGroup = { fg = c.blue },
    WhichKeyDesc = { fg = c.white3 },
    WhichKeySeparator = { fg = c.blue4 },
    WhichKeyFloat = { bg = c.ui_bar },
    WhichKeyBorder = { fg = c.blue4, bg = c.ui_bar },

    NotifyERRORBorder = { fg = c.red },
    NotifyWARNBorder = { fg = c.orange },
    NotifyINFOBorder = { fg = c.blue },
    NotifyDEBUGBorder = { fg = c.blue4 },
    NotifyTRACEBorder = { fg = c.pink },
    NotifyERRORIcon = { fg = c.red },
    NotifyWARNIcon = { fg = c.orange },
    NotifyINFOIcon = { fg = c.blue },
    NotifyDEBUGIcon = { fg = c.blue4 },
    NotifyTRACEIcon = { fg = c.pink },
    NotifyERRORTitle = { fg = c.red, bold = true },
    NotifyWARNTitle = { fg = c.orange, bold = true },
    NotifyINFOTitle = { fg = c.blue, bold = true },
    NotifyDEBUGTitle = { fg = c.blue4, bold = true },
    NotifyTRACETitle = { fg = c.pink, bold = true },

    -- Bufferline
    BufferLineFill = { bg = c.ui_deep },
    BufferLineBackground = { fg = c.blue4, bg = c.ui_deep },
    BufferLineBufferSelected = { fg = c.white3, bg = c.blue3, bold = true },
    BufferLineIndicatorSelected = { fg = c.blue_vib, bg = c.blue3 },
    BufferLineModified = { fg = c.orange, bg = c.ui_deep },
    BufferLineModifiedSelected = { fg = c.orange, bg = c.blue3 },

    -- Misc Plugins
    FlashLabel = { fg = c.grey, bg = c.orange3, bold = true },
    LeapLabelPrimary = { fg = c.grey, bg = c.orange3, bold = true },
    LeapMatch = { fg = c.orange, bold = true },

    MiniStatuslineModeNormal = { fg = c.blue3, bg = c.blue_vib, bold = true },
    MiniStatuslineModeInsert = { fg = c.blue3, bg = c.green, bold = true },
    MiniStatuslineModeVisual = { fg = c.blue3, bg = c.pink, bold = true },
    MiniStatuslineModeReplace = { fg = c.blue3, bg = c.red, bold = true },
    MiniStatuslineModeCommand = { fg = c.grey, bg = c.orange, bold = true },
    MiniStatuslineDevinfo = { fg = c.blue6, bg = c.ui_light },
    MiniStatuslineFilename = { fg = c.blue6, bg = c.ui_bar },

    -- ─── Built-in ft ─────────────────────────────────────────────────────
    htmlTag = { fg = c.blue5 },
    htmlEndTag = { fg = c.blue5 },
    htmlTagName = { fg = c.red },
    htmlArg = { fg = c.pink },
    htmlH1 = { bold = true },
    cssTagName = { fg = c.red },
    cssClassName = { fg = c.orange },
    cssIdentifier = { fg = c.orange },
    cssProp = { fg = c.white3 },
    cssBraces = { fg = c.white },
    markdownHeadingDelimiter = { fg = c.red2 },
    markdownH1 = { bold = true },
    markdownCode = { bg = c.raw_bg_inline },
    markdownCodeBlock = { bg = c.raw_bg },
    markdownLinkText = { fg = c.blue },
    markdownUrl = { fg = c.blue },
    markdownListMarker = { fg = c.orange },
    markdownRule = { fg = c.orange },
    helpHyperTextEntry = { fg = c.blue },
    helpHyperTextJump = { fg = c.blue, underline = true },
    helpExample = { fg = c.green },
    qfFileName = { fg = c.blue },
    qfLineNr = { fg = c.blue4 },
  }

  return groups
end

local groups = setcolor()

for group, settings in pairs(groups) do
  vim.api.nvim_set_hl(0, group, settings)
end

-- ─── Terminal Colors ─────────────────────────────────────────────────────
local term_colors = {
  colors.ui_bar,
  colors.red,
  colors.green,
  colors.orange3,
  colors.blue,
  colors.pink,
  colors.blue5,
  colors.white3,
  colors.blue4,
  colors.red2,
  colors.green,
  colors.orange,
  colors.blue_vib,
  colors.pink,
  colors.blue5,
  colors.white,
}
for i, color in ipairs(term_colors) do
  vim.g['terminal_color_' .. (i - 1)] = color
end
