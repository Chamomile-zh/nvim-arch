-- Tokyo Night Theme (Night Variant)
-- Refactored into a high-performance modular table structure

-- ─── 1. Palette Generation (Tokyo Night Official Colors) ───────────────
local c = {
  -- Core Backgrounds
  bg = '#1a1b26',
  bg_highlight = '#292e42',
  selection_bg = '#283457',
  float_bg = '#16161e',

  -- Core Foregrounds
  fg_comment = '#565f89',
  fg = '#c0caf5',
  fg_emphasis = '#a9b1d6',
  fg_bright = '#ffffff',

  -- Neon Accents
  cyan = '#7dcfff',
  blue = '#7aa2f7',
  teal = '#73daca',
  green = '#9ece6a',
  yellow = '#e0af68',
  orange = '#ff9e64',
  red = '#f7768e',
  magenta = '#bb9af7',
  violet = '#9d7cd8',

  -- Special elements
  cursorline_bg = '#292e42',

  -- Diagnostic Variants
  sl_diag_error = '#db4b4b',
  sl_diag_warn = '#e0af68',
  sl_diag_info = '#0db9d7',
  sl_diag_hint = '#1abc9c',

  -- Diff variants
  diff_plus = '#283b4d',
  diff_minus = '#3f2d3d',
  diff_delta = '#32344a',
}

-- ─── 2. Blend Utilities ──────────────────────────────────────────────
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

-- ─── 3. Initialization ───────────────────────────────────────────────
vim.cmd('highlight clear')
if vim.fn.exists('syntax_on') == 1 then
  vim.cmd('syntax reset')
end
vim.g.colors_name = 'tokyonight'

vim.api.nvim_create_user_command('ColorOutPut', function()
  for k, v in pairs(c) do
    print(('%s = "%s"'):format(k, v))
  end
end, {})

-- ─── 4. Highlight Groups Builder ─────────────────────────────────────
local function setcolor()
  local groups = {
    -- Core Editor Surface
    Normal = { fg = c.fg, bg = c.bg },
    EndOfBuffer = { fg = c.bg },
    CursorLine = { bg = c.cursorline_bg },
    CursorLineNr = { fg = c.orange, bold = true },
    LineNr = { fg = c.fg_comment },
    WinSeparator = { fg = c.bg_highlight, bg = c.bg },

    -- Visual & Search
    Visual = { bg = c.selection_bg },
    Search = { fg = c.bg, bg = c.cyan },
    IncSearch = { fg = c.bg, bg = c.orange },

    -- Syntax (Tokyo Night Mapping)
    Keyword = { fg = c.magenta, italic = true },
    Statement = { fg = c.magenta },
    Conditional = { fg = c.magenta, italic = true },
    Repeat = { fg = c.magenta },
    Function = { fg = c.blue, bold = true },
    Type = { fg = c.teal },
    StorageClass = { fg = c.magenta },
    Structure = { fg = c.teal },
    Typedef = { fg = c.teal },
    Constant = { fg = c.orange },
    String = { fg = c.green },
    Character = { fg = c.green },
    Number = { fg = c.orange },
    Boolean = { fg = c.orange },
    Float = { fg = c.orange },
    PreProc = { fg = c.cyan },
    Include = { fg = c.cyan },
    Define = { fg = c.magenta },
    Macro = { fg = c.violet },
    PreCondit = { fg = c.cyan },
    Special = { fg = c.blue },
    Identifier = { fg = c.fg },
    Variable = { fg = c.fg },
    Operator = { fg = c.cyan },
    Delimiter = { fg = c.fg_emphasis },
    NonText = { fg = c.fg_comment },
    Comment = { fg = c.fg_comment, italic = true },

    -- UI Components
    StatusLine = { fg = c.fg, bg = 'NONE' },
    StatusLineNC = { fg = c.fg_comment, bg = 'NONE' },
    WildMenu = { fg = c.bg, bg = c.blue },
    ColorColumn = { bg = c.bg_highlight },
    WhiteSpace = { fg = c.bg_highlight },

    -- Popup Menu
    Pmenu = { fg = c.fg, bg = c.float_bg },
    PmenuSel = { fg = c.bg, bg = c.blue, bold = true },
    PmenuSbar = { bg = c.float_bg },
    PmenuThumb = { bg = c.fg_comment },
    PmenuBorder = { fg = c.bg_highlight },

    -- Winbar
    WinBar = { fg = c.fg_comment, bg = c.bg },
    WinBarNC = { fg = c.bg_highlight, bg = c.bg },

    -- Float & Borders
    NormalFloat = { bg = c.float_bg },
    FloatBorder = { fg = c.blue, bg = c.float_bg },
    Title = { fg = c.blue, bold = true },

    -- Messages & Misc
    ErrorMsg = { fg = c.red, bold = true },
    WarningMsg = { fg = c.yellow },
    ModeMsg = { fg = c.fg_bright, bold = true },
    Todo = { fg = c.bg, bg = c.yellow, bold = true },
    MatchParen = { fg = c.orange, bold = true },
    Underlined = { fg = c.cyan, underline = true },
    Directory = { fg = c.blue },
    Magenta = { fg = c.magenta },
    Violet = { fg = c.violet },

    -- QuickFix
    qfFileName = { fg = c.blue },
    qfLineNr = { fg = c.orange },
    qfSeparator = { fg = c.bg_highlight },
    QuickFixLine = { bg = c.selection_bg, bold = true },
    qfText = { link = 'Normal' },

    -- Treesitter Highlights
    ['@variable'] = { fg = c.fg },
    ['@variable.builtin'] = { fg = c.red },
    ['@variable.parameter'] = { fg = c.yellow },
    ['@variable.member'] = { fg = c.teal },
    ['@property'] = { fg = c.teal },
    ['@constant'] = { fg = c.orange },
    ['@constant.builtin'] = { fg = c.orange },
    ['@constant.macro'] = { fg = c.violet },
    ['@module'] = { fg = c.cyan },
    ['@label'] = { fg = c.blue },
    ['@string'] = { link = 'String' },
    ['@string.regexp'] = { fg = c.blue },
    ['@string.escape'] = { fg = c.magenta },
    ['@character'] = { link = 'String' },
    ['@boolean'] = { link = 'Boolean' },
    ['@number'] = { link = 'Number' },
    ['@type'] = { fg = c.teal },
    ['@type.builtin'] = { fg = c.teal, italic = true },
    ['@attribute'] = { fg = c.magenta },
    ['@function'] = { fg = c.blue, bold = true },
    ['@function.builtin'] = { fg = c.cyan, bold = true },
    ['@function.macro'] = { fg = c.cyan, bold = true },
    ['@constructor'] = { fg = c.magenta },
    ['@operator'] = { fg = c.cyan },
    ['@keyword'] = { fg = c.magenta, italic = true },
    ['@keyword.modifier'] = { fg = c.teal },
    ['@keyword.return'] = { fg = c.magenta, italic = true },
    ['@keyword.conditional'] = { fg = c.magenta, italic = true },
    ['@punctuation.delimiter'] = { fg = c.cyan },
    ['@punctuation.bracket'] = { fg = c.fg_emphasis },
    ['@comment'] = { link = 'Comment' },
    ['@comment.error'] = { fg = c.bg, bg = c.red, bold = true },
    ['@comment.warning'] = { fg = c.bg, bg = c.yellow, bold = true },
    ['@comment.todo'] = { fg = c.bg, bg = c.cyan, bold = true },

    ['@lsp.type.class'] = { link = '@type' },
    ['@lsp.type.comment'] = { link = '@comment' },
    ['@lsp.type.decorator'] = { link = '@attribute' },
    ['@lsp.type.enum'] = { link = '@type' },
    ['@lsp.type.enumMember'] = { fg = c.teal },
    ['@lsp.type.function'] = { link = '@function' },
    ['@lsp.type.interface'] = { fg = c.teal },
    ['@lsp.type.macro'] = { link = 'Macro' },
    ['@lsp.type.method'] = { link = '@function' },
    ['@lsp.type.namespace'] = { link = '@module' },
    ['@lsp.type.parameter'] = { link = '@variable.parameter' },
    ['@lsp.type.property'] = { link = '@property' },
    ['@lsp.type.struct'] = { link = '@type' },
    ['@lsp.type.type'] = { link = '@type' },
    ['@lsp.type.variable'] = { link = '@variable' },

    ['@lsp.typemod.variable.readonly'] = { fg = c.violet, bold = true },
    ['@lsp.type.snippet'] = { fg = c.magenta },
    ['@lsp.type.reference'] = { fg = c.fg_comment, underline = true },

    DiagnosticError = { fg = c.sl_diag_error },
    DiagnosticWarn = { fg = c.sl_diag_warn },
    DiagnosticInfo = { fg = c.sl_diag_info },
    DiagnosticHint = { fg = c.sl_diag_hint },
    DiagnosticVirtualTextError = { fg = c.sl_diag_error, bg = 'NONE' },
    DiagnosticVirtualTextWarn = { fg = c.sl_diag_warn, bg = 'NONE' },
    DiagnosticVirtualTextInfo = { fg = c.sl_diag_info, bg = 'NONE' },
    DiagnosticVirtualTextHint = { fg = c.sl_diag_hint, bg = 'NONE' },

    DiagnosticUnderlineError = { undercurl = true, sp = c.sl_diag_error },
    DiagnosticUnderlineWarn = { undercurl = true, sp = c.sl_diag_warn },
    DiagnosticUnderlineInfo = { undercurl = true, sp = c.sl_diag_info },
    DiagnosticUnderlineHint = { undercurl = true, sp = c.sl_diag_hint },

    -- Statusline Diagnostics
    DiagnosticERROR = { fg = c.sl_diag_error },
    DiagnosticWARN = { fg = c.sl_diag_warn },
    DiagnosticINFO = { fg = c.sl_diag_info },
    DiagnosticHINT = { fg = c.sl_diag_hint },

    -- Rainbow delimiters
    RainbowBracket1 = { fg = c.magenta, bold = true },
    RainbowBracket2 = { fg = c.cyan, bold = true },
    RainbowBracket3 = { fg = c.yellow, bold = true },
    RainbowBracket4 = { fg = c.green, bold = true },
    RainbowBracket5 = { fg = c.orange, bold = true },
    RainbowBracket6 = { fg = c.blue, bold = true },

    -- Plugins Support
    LspReferenceText = { bg = c.selection_bg },
    LspReferenceRead = { bg = c.selection_bg },
    LspReferenceWrite = { bg = c.selection_bg },
    LspInlayHint = { fg = c.fg_comment, italic = true },

    IndentLine = { fg = c.bg_highlight },
    IndentLineCurrent = { fg = c.magenta }, -- 当前缩进线使用亮紫色

    GitSignsAdd = { fg = c.green },
    GitSignsChange = { fg = c.blue },
    GitSignsDelete = { fg = c.red },

    -- 🌸 Dashboard 专属定制
    DashboardKey = { fg = c.magenta, bold = true },
    DashboardDesc = { fg = c.blue },
    DashboardDate = { fg = c.teal },
    DashboardFooter = { fg = c.fg_comment, italic = true },
    DashboardGreeting = { fg = c.red, bold = true, italic = true },
    ModeLineFileName = { fg = c.fg_bright, bold = true },
  }

  return groups
end

for group, settings in pairs(setcolor()) do
  vim.api.nvim_set_hl(0, group, settings)
end
