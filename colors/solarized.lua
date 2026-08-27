-- Solarized Oklab Theme
-- Refactored into a modular table structure

-- ─── 1. Oklab Core Math (Runs only once during init) ─────────────────
local function oklab_to_srgb(L, a, b)
  local l = L + 0.3963377774 * a + 0.2158037573 * b
  local m = L - 0.1055613458 * a - 0.0638541728 * b
  local s = L - 0.0894841775 * a - 1.2914855480 * b

  local l3, m3, s3 = l * l * l, m * m * m, s * s * s

  local r = 4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3
  local g = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3
  local b_out = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3

  local function compand(c)
    return c <= 0.0031308 and (c * 12.92) or (1.055 * (c ^ (1 / 2.4)) - 0.055)
  end

  r, g, b_out = compand(r), compand(g), compand(b_out)

  r = math.floor(math.max(0, math.min(1, r)) * 255 + 0.5)
  g = math.floor(math.max(0, math.min(1, g)) * 255 + 0.5)
  b_out = math.floor(math.max(0, math.min(1, b_out)) * 255 + 0.5)

  return string.format('#%02x%02x%02x', r, g, b_out)
end

-- ─── 2. Palette Generation ───────────────────────────────────────────
local is_dark = vim.o.background == 'dark' or vim.o.background == ''

local c = {
  -- Base tones
  base04 = oklab_to_srgb(0.423013, -0.020000, -0.008000),
  base03 = oklab_to_srgb(0.267337, -0.037339, -0.031128),
  base02 = oklab_to_srgb(0.322000, -0.038500, -0.032000),
  base01 = oklab_to_srgb(0.523013, -0.020000, -0.010000),
  base00 = oklab_to_srgb(0.568165, -0.019000, -0.010000),
  base0 = oklab_to_srgb(0.702000, -0.016000, -0.005000),
  base1 = oklab_to_srgb(0.698000, -0.014000, -0.002000),
  base2 = oklab_to_srgb(0.930609, -0.001000, 0.026000),
  base3 = oklab_to_srgb(0.973528, 0.000000, 0.026000),

  -- Accents
  yellow = oklab_to_srgb(0.654000, 0.010000, 0.134000),
  red = oklab_to_srgb(0.610000, 0.118000, 0.030000),
  orange = oklab_to_srgb(0.635000, 0.082000, 0.090000),
  magenta = oklab_to_srgb(0.600000, 0.124000, -0.009000),
  blue = oklab_to_srgb(0.630000, -0.047000, -0.101000),
  violet = oklab_to_srgb(0.597000, 0.016000, -0.100000),
  cyan = oklab_to_srgb(0.643664, -0.101063, -0.013097),
  green = oklab_to_srgb(0.648000, -0.068000, 0.125000),

  -- Special elements
  cursorline_bg = oklab_to_srgb(0.298000, -0.038000, -0.031500),
  float_bg = oklab_to_srgb(0.289370, -0.037339, -0.031128),
  statusline_bg = oklab_to_srgb(0.440000, -0.022000, -0.010000),

  -- Diagnostic Variants (Statusline)
  sl_diag_error = oklab_to_srgb(0.490000, 0.115000, 0.055000),
  sl_diag_warn = oklab_to_srgb(0.520000, 0.008000, 0.115000),
  sl_diag_info = oklab_to_srgb(0.510000, -0.040000, -0.086000),
  sl_diag_hint = oklab_to_srgb(0.510000, -0.070000, -0.011000),

  -- Diff variants
  diff_plus = oklab_to_srgb(0.490000, -0.080000, 0.115000),
  diff_minus = oklab_to_srgb(0.480000, 0.118000, 0.055000),
  diff_delta = oklab_to_srgb(0.500000, 0.085000, 0.095000),
}

-- Resolve logical roles based on background mode
c.bg = is_dark and c.base03 or c.base3
c.bg_highlight = is_dark and c.base02 or c.base2
c.fg_comment = is_dark and c.base01 or c.base1
c.fg = is_dark and c.base0 or c.base00
c.fg_emphasis = is_dark and c.base1 or c.base01
c.selection_bg = is_dark and c.base02 or c.base2

-- ─── 3. Blend Utilities ──────────────────────────────────────────────
local function hex_to_rgb(hex)
  hex = hex:gsub('#', '')
  return { tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16) }
end

local function rgb_to_hex(rgb)
  return string.format('#%02x%02x%02x', rgb[1], rgb[2], rgb[3])
end

local function blend(fg, t, target_bg)
  local a, b = hex_to_rgb(fg), hex_to_rgb(target_bg or c.bg)
  return rgb_to_hex({
    math.floor(a[1] * (1 - t) + b[1] * t + 0.5),
    math.floor(a[2] * (1 - t) + b[2] * t + 0.5),
    math.floor(a[3] * (1 - t) + b[3] * t + 0.5),
  })
end

-- ─── 4. Initialization ───────────────────────────────────────────────
vim.cmd('highlight clear')
if vim.fn.exists('syntax_on') == 1 then
  vim.cmd('syntax reset')
end
vim.g.colors_name = 'solarized'

-- User Command
vim.api.nvim_create_user_command('ColorOutPut', function()
  for k, v in pairs(c) do
    print(('%s = "%s"'):format(k, v))
  end
end, {})

-- ─── 5. Highlight Groups Builder ─────────────────────────────────────
local function setcolor()
  local groups = {
    -- Core Editor Surface
    Normal = { fg = c.fg, bg = c.bg },
    EndOfBuffer = { fg = c.bg },
    CursorLine = { bg = c.cursorline_bg },
    CursorLineNr = { fg = c.base1, bold = true },
    LineNr = { fg = c.fg_comment },
    WinSeparator = { fg = c.bg_highlight, bg = c.bg },

    -- Visual & Search
    Visual = { bg = c.selection_bg },
    Search = { fg = c.bg, bg = c.yellow },
    IncSearch = { fg = c.bg, bg = c.orange },

    -- Syntax
    Keyword = { fg = c.green },
    Statement = { fg = c.green },
    Conditional = { fg = c.green },
    Repeat = { fg = c.green },
    Function = { fg = c.blue },
    Type = { fg = c.yellow },
    StorageClass = { fg = c.yellow },
    Structure = { fg = c.yellow },
    Typedef = { fg = c.yellow },
    Constant = { fg = c.cyan },
    String = { fg = c.cyan },
    Character = { fg = c.cyan },
    Number = { fg = c.cyan },
    Boolean = { fg = c.cyan },
    Float = { fg = c.cyan },
    PreProc = { fg = c.orange },
    Include = { fg = c.orange },
    Define = { fg = c.orange },
    Macro = { fg = c.orange },
    PreCondit = { fg = c.orange },
    Special = { fg = c.cyan },
    Identifier = { fg = c.fg },
    Variable = { fg = c.fg },
    Operator = { fg = c.fg },
    Delimiter = { fg = c.fg },
    NonText = { fg = c.bg_highlight },
    Comment = { fg = c.fg_comment, italic = true },

    -- UI Components
    StatusLine = { fg = c.fg_comment, bg = c.bg },
    StatusLineNC = { fg = c.bg_highlight, bg = c.bg },
    WildMenu = { fg = c.bg, bg = c.blue },
    ColorColumn = { bg = c.bg_highlight },
    WhiteSpace = { fg = c.base04 },

    -- Popup Menu
    Pmenu = { fg = c.fg, bg = c.base02 },
    PmenuSel = { fg = c.bg, bg = c.fg },
    PmenuSbar = { bg = c.base02 },
    PmenuThumb = { bg = c.base01 },
    PmenuBorder = { fg = c.fg_comment },
    -- Winbar
    WinBar = { fg = c.fg_comment, bg = c.bg },
    WinBarNC = { fg = c.bg_highlight, bg = c.bg },

    -- Lspsaga Winbar
    LspSagaWinbarWord = { fg = c.fg }, -- 文字颜色
    LspSagaWinbarSep = { fg = c.cyan }, -- 分隔符颜色（比如 > ）
    LspSagaWinbarFile = { fg = c.fg_emphasis }, -- 文件名
    LspSagaWinbarFolder = { fg = c.blue }, -- 文件夹

    -- Float & Borders
    NormalFloat = { bg = c.base02 },
    FloatBorder = { fg = blend(c.fg_comment, 0.40), bg = c.bg },
    Title = { fg = c.yellow, bold = true },

    -- Messages & Misc
    ErrorMsg = { fg = c.red, bold = true },
    WarningMsg = { fg = c.orange },
    ModeMsg = { fg = c.cyan, bold = true },
    Todo = { fg = c.violet, bold = true, reverse = true },
    MatchParen = { bg = c.selection_bg, bold = true },
    Underlined = { fg = c.violet, underline = true },
    Directory = { fg = c.blue },
    Magenta = { fg = c.magenta },
    Violet = { fg = c.violet },

    -- QuickFix
    qfFileName = { fg = c.blue },
    qfLineNr = { fg = c.cyan },
    qfSeparator = { fg = c.bg_highlight },
    QuickFixLine = { bg = c.cursorline_bg, bold = true },
    qfText = { link = 'Normal' },

    -- Treesitter Highlights
    ['@variable'] = { link = 'Identifier' },
    ['@variable.builtin'] = { link = '@variable' },
    ['@variable.parameter'] = { link = '@variable' },
    ['@variable.parameter.builtin'] = { link = '@variable.builtin' },
    ['@variable.member'] = { link = '@variable' },
    ['@parameter'] = { fg = c.fg },
    ['@property'] = { fg = c.fg },
    ['@constant'] = { fg = c.cyan },
    ['@constant.builtin'] = { fg = c.cyan },
    ['@constant.macro'] = { fg = c.cyan },
    ['@module'] = { link = 'Identifier' },
    ['@module.builtin'] = { link = '@module' },
    ['@label'] = { link = 'Label' },
    ['@string'] = { link = 'String' },
    ['@string.documentation'] = { link = 'Comment' },
    ['@string.regexp'] = { link = '@string' },
    ['@string.escape'] = { link = 'Special' },
    ['@string.special'] = { link = '@string' },
    ['@string.special.symbol'] = { link = '@string' },
    ['@string.special.path'] = { link = '@string' },
    ['@string.special.url'] = { link = 'Underlined' },
    ['@character'] = { link = 'String' },
    ['@character.special'] = { link = '@character' },
    ['@boolean'] = { link = 'Constant' },
    ['@number'] = { link = 'Number' },
    ['@number.float'] = { link = 'Float' },
    ['@type'] = { link = 'Type' },
    ['@type.builtin'] = { link = 'Type' },
    ['@type.definition'] = { link = 'Type' },
    ['@attribute'] = { link = 'Macro' },
    ['@attribute.builtin'] = { link = 'Special' },
    ['@function'] = { link = 'Function' },
    ['@function.builtin'] = { link = 'Function' },
    ['@function.call'] = { link = '@function' },
    ['@function.macro'] = { link = '@function' },
    ['@function.method'] = { link = '@function' },
    ['@function.method.call'] = { link = '@function' },
    ['@constructor'] = { link = 'Function' },
    ['@operator'] = { link = 'Operator' },
    ['@keyword'] = { link = 'Keyword' },
    ['@keyword.coroutine'] = { link = '@keyword' },
    ['@keyword.function'] = { link = 'Keyword' },
    ['@keyword.operator'] = { link = '@keyword' },
    ['@keyword.import'] = { link = 'PreProc' },
    ['@keyword.type'] = { link = '@keyword' },
    ['@keyword.modifier'] = { link = '@keyword' },
    ['@keyword.repeat'] = { link = 'Repeat' },
    ['@keyword.return'] = { link = '@keyword' },
    ['@keyword.debug'] = { link = '@keyword' },
    ['@keyword.exception'] = { link = '@keyword' },
    ['@keyword.conditional'] = { link = 'Conditional' },
    ['@keyword.conditional.ternary'] = { link = '@operator' },
    ['@keyword.directive'] = { link = '@keyword' },
    ['@keyword.directive.define'] = { link = '@keyword' },
    ['@punctuation'] = { fg = c.fg },
    ['@punctuation.delimiter'] = { link = '@punctuation' },
    ['@punctuation.bracket'] = { link = '@punctuation' },
    ['@punctuation.special'] = { link = '@punctuation' },
    ['@comment'] = { link = 'Comment' },
    ['@comment.documentation'] = { link = '@comment' },
    ['@comment.error'] = { fg = c.red, bold = true },
    ['@comment.warning'] = { fg = c.yellow, bold = true },
    ['@comment.todo'] = { link = 'Special' },
    ['@comment.note'] = { link = 'Special' },
    ['@markup'] = { link = 'Comment' },
    ['@markup.strong'] = { bold = true },
    ['@markup.italic'] = { italic = true },
    ['@markup.strikethrough'] = { strikethrough = true },
    ['@markup.underline'] = { link = 'Underlined' },
    ['@markup.heading'] = { link = 'Title' },
    ['@markup.heading.1'] = { link = '@markup.heading' },
    ['@markup.heading.2'] = { link = '@markup.heading' },
    ['@markup.heading.3'] = { link = '@markup.heading' },
    ['@markup.heading.4'] = { link = '@markup.heading' },
    ['@markup.heading.5'] = { link = '@markup.heading' },
    ['@markup.heading.6'] = { link = '@markup.heading' },
    ['@markup.quote'] = {},
    ['@markup.math'] = { link = 'String' },
    ['@markup.link'] = { link = 'Underlined' },
    ['@markup.link.label'] = { link = '@markup.link' },
    ['@markup.link.url'] = { link = '@markup.link' },
    ['@markup.raw'] = {},
    ['@markup.raw.block'] = { link = '@markup.raw' },
    ['@markup.list'] = {},
    ['@markup.list.checked'] = { fg = c.green },
    ['@markup.list.unchecked'] = { link = '@markup.list' },

    -- Diff Treesitter
    ['@diff.plus'] = { fg = c.diff_plus },
    ['@diff.minus'] = { fg = c.diff_minus },
    ['@diff.delta'] = { fg = c.diff_delta },
    ['@tag'] = { fg = c.green },
    ['@tag.attribute'] = { fg = c.fg },
    ['@tag.delimiter'] = { fg = c.fg },
    ['@tag.builtin'] = { link = 'Special' },

    ['@constant.comment'] = { link = 'SpecialComment' },
    ['@number.comment'] = { link = 'Comment' },
    ['@punctuation.bracket.comment'] = { link = 'SpecialComment' },
    ['@punctuation.delimiter.comment'] = { link = 'SpecialComment' },
    ['@label.vimdoc'] = { link = 'String' },
    ['@markup.heading.1.delimiter.vimdoc'] = { link = '@markup.heading.1' },
    ['@markup.heading.2.delimiter.vimdoc'] = { link = '@markup.heading.2' },

    ['@class'] = { fg = c.yellow },
    ['@method'] = { fg = c.blue },
    ['@interface'] = { fg = c.yellow },
    ['@namespace'] = { fg = c.fg },

    -- LSP Semantic Highlights
    ['@lsp.type.class'] = { link = '@type' },
    ['@lsp.type.comment'] = { link = '@comment' },
    ['@lsp.type.decorator'] = { link = '@attribute' },
    ['@lsp.type.enum'] = { link = '@type' },
    ['@lsp.type.enumMember'] = { link = '@constant' },
    ['@lsp.type.event'] = { link = '@type' },
    ['@lsp.type.function'] = { link = '@function' },
    ['@lsp.type.interface'] = { link = '@type' },
    ['@lsp.type.keyword'] = { link = '@keyword' },
    ['@lsp.type.macro'] = { link = 'Macro' },
    ['@lsp.type.method'] = { link = '@function.method' },
    ['@lsp.type.modifier'] = { link = '@type.qualifier' },
    ['@lsp.type.namespace'] = { link = '@module' },
    ['@lsp.type.number'] = { link = '@number' },
    ['@lsp.type.operator'] = { link = '@operator' },
    ['@lsp.type.parameter'] = { fg = c.fg },
    ['@lsp.type.property'] = { fg = c.fg },
    ['@lsp.type.regexp'] = { link = '@string.regexp' },
    ['@lsp.type.string'] = { link = '@string' },
    ['@lsp.type.struct'] = { link = '@type' },
    ['@lsp.type.type'] = { link = '@type' },
    ['@lsp.type.typeParameter'] = { link = '@type.definition' },
    ['@lsp.type.variable'] = { link = '@variable' },

    ['@lsp.mod.abstract'] = {},
    ['@lsp.mod.async'] = {},
    ['@lsp.mod.declaration'] = {},
    ['@lsp.mod.defaultLibrary'] = {},
    ['@lsp.mod.definition'] = {},
    ['@lsp.mod.deprecated'] = { link = 'DiagnosticDeprecated' },
    ['@lsp.mod.documentation'] = {},
    ['@lsp.mod.modification'] = {},
    ['@lsp.mod.readonly'] = {},
    ['@lsp.mod.static'] = {},

    -- Diagnostics Base
    DiagnosticError = { fg = c.red },
    DiagnosticWarn = { fg = c.yellow },
    DiagnosticInfo = { fg = c.blue },
    DiagnosticHint = { fg = c.cyan },

    DiagnosticVirtualTextError = { fg = c.red, bg = 'NONE' },
    DiagnosticVirtualTextWarn = { fg = c.yellow, bg = 'NONE' },
    DiagnosticVirtualTextInfo = { fg = c.blue, bg = 'NONE' },
    DiagnosticVirtualTextHint = { fg = c.cyan, bg = 'NONE' },

    DiagnosticPrefixError = { fg = c.red, bg = blend(c.red, 0.25) },
    DiagnosticPrefixWarn = { fg = c.yellow, bg = blend(c.yellow, 0.25) },
    DiagnosticPrefixInfo = { fg = c.blue, bg = blend(c.blue, 0.25) },
    DiagnosticPrefixHint = { fg = c.cyan, bg = blend(c.cyan, 0.25) },

    DiagnosticUnderlineError = { undercurl = true, sp = c.red },
    DiagnosticUnderlineWarn = { undercurl = true, sp = c.yellow },
    DiagnosticUnderlineInfo = { undercurl = true, sp = c.blue },
    DiagnosticUnderlineHint = { undercurl = true, sp = c.cyan },

    -- Rainbow delimiters
    RainbowBracket1 = { fg = c.magenta, bold = true },
    RainbowBracket2 = { fg = c.blue, bold = true },
    RainbowBracket3 = { fg = c.cyan, bold = true },
    RainbowBracket4 = { fg = c.green, bold = true },
    RainbowBracket5 = { fg = c.yellow, bold = true },
    RainbowBracket6 = { fg = c.orange, bold = true },

    YankHighlight = { fg = c.bg, bg = c.fg },

    -- Statusline Diagnostics
    DiagnosticERROR = { fg = c.sl_diag_error },
    DiagnosticWARN = { fg = c.sl_diag_warn },
    DiagnosticINFO = { fg = c.sl_diag_info },
    DiagnosticHINT = { fg = c.sl_diag_hint },

    -- Plugins Support
    LspReferenceText = { bg = c.selection_bg },
    LspReferenceRead = { bg = c.selection_bg },
    LspReferenceWrite = { bg = c.selection_bg },
    LspReferenceTarget = { link = 'LspReferenceText' },
    LspInlayHint = { link = 'NonText' },
    LspCodeLens = { link = 'NonText' },
    LspCodeLensSeparator = { link = 'NonText' },
    LspSignatureActiveParameter = { link = 'LspReferenceText' },

    IndentLine = { link = 'Comment' },
    IndentLineCurrent = { fg = c.cyan },

    GitSignsAdd = { fg = c.green },
    GitSignsChange = { fg = c.orange },
    GitSignsDelete = { fg = c.red },

    DashboardHeader = { fg = c.green },
    ModeLineFileName = { fg = c.bg_highlight, bold = true },
  }

  return groups
end

-- Apply Theme
for group, settings in pairs(setcolor()) do
  vim.api.nvim_set_hl(0, group, settings)
end
