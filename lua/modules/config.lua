local config = {}

config.lspsaga = function()
  require('lspsaga').setup({
    ui = {
      devicon = false,
    },
    lightbulb = {
      enable = false,
    },
    finder = {
      keys = {
        edit = '<C-o>',
        toggle_or_open = '<cr>',
      },
    },
    definition = {
      keys = {
        edit = '<C-o>',
        vsplit = '<C-v>',
      },
    },
  })
end

config.blink = function()
  -- require('blink.cmp').build():pwait()
  require('blink.cmp').setup({
    keymap = {
      ['<tab>'] = {
        'select_next',
        'snippet_forward',
        'fallback',
      },
      ['<s-tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
      ['<cr>'] = { 'accept', 'fallback' },
      -- ['<c-space>'] = {
      --   function(cmp)
      --     return cmp.show()
      --   end,
      -- },
    },
    appearance = { kind_icons = icons },
    completion = {
      menu = {
        border = 'rounded',
        winhighlight = 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:CursorLine,Search:None',
        draw = {
          columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 }, { 'kind' } },
        },
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 0,
        treesitter_highlighting = true,
        window = {
          border = 'rounded',
          winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:CursorLine,Search:None',
        },
      },
      list = { selection = { preselect = false, auto_insert = true } },
      accept = { auto_brackets = { enabled = true } },
      ghost_text = { enabled = true },
    },
    sources = { default = { 'snippets', 'lsp', 'path', 'buffer' } },
    cmdline = {
      completion = {
        menu = { auto_show = true },
        list = { selection = { preselect = false } },
      },
    },
    signature = { window = { border = 'rounded' } },
  })
end

config.treesitter = function()
  require('nvim-treesitter').setup({
    install_dir = vim.fn.stdpath('data') .. '/site',
  })
end

config.guard = function()
  local ft = require('guard.filetype')
  ft('c,cpp'):fmt({
    cmd = 'clang-format',
    stdin = true,
    ignore_patterns = { 'neovim', 'vim' },
  })
  ft('python'):fmt({
    cmd = 'black',
    args = { '--quiet', '-' },
    stdin = true,
  })
  ft('lua'):fmt({
    cmd = 'stylua',
    args = { '-' },
    stdin = true,
    find = 'stylua.toml', -- must have the file in your directory
  })
  ft('sh'):fmt({
    cmd = 'shfmt',
    args = { '-' },
    stdin = true,
  })
  ft('go', 'html', 'css', 'javascript', 'json', 'rust'):fmt('lsp')

  vim.g.guard_config = {
    fmt_on_save = false,
    lsp_as_default_formatter = true,
  }
end

config.fzflua = function()
  local actions = require('fzf-lua.actions')
  require('fzf-lua').setup({
    actions = {
      ['default'] = actions.file_edit,
    },
    lsp = { symbols = { symbol_style = 3 } },
    grep = {
      rg_opts = "--column --line-number --no-heading --color=always --smart-case --colors 'path:fg:blue'",
    },
    live_grep = {
      rg_opts = "--column --line-number --no-heading --color=always --smart-case --colors 'path:fg:blue'",
    },
    winopts = {
      preview = {
        default = true,
        builtin = {
          treesitter = { enabled = false },
        },
      },
    },
    files = {
      file_icons = false,
      hidden = false,
    },
  })
end

config.gitsigens = function()
  require('gitsigns').setup({
    signs = {
      add = { text = '┃' },
      change = { text = '┃' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
      untracked = { text = '┃' },
    },
  })
end

config.indentmini = function()
  vim.opt.listchars:append({ tab = '  ' })
  require('indentmini').setup({
    char = '│',
    exclude = {
      'help',
      'dashboard',
      'lazy',
      'markdown',
      'text',
    },
  })
end

config.noice = function()
  require('notify').setup({
    background_colour = '#000000',
  })
  require('noice').setup({
    popmenu = { enabled = true },
    presets = {
      bottom_search = false, -- use a classic bottom cmdline for search
      command_palette = true, -- position the cmdline and popupmenu together
      long_message_to_split = true, -- long messages will be sent to a split
      inc_rename = false, -- enables an input dialog for inc-rename.nvim
      lsp_doc_border = true, -- add a border to hover docs and signature help
    },
    lsp = {
      override = {
        ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
        ['vim.lsp.util.stylize_markdown'] = true,
      },
      progress = { enabled = false }, -- 依旧关闭烦人的 LSP 进度条提示
    },
    -- 需要过滤的信息
    routes = {
      -- {
      --   -- 过滤打开rust文件不影响使用的错误提示
      --   filter = {
      --     event = 'msg_show',
      --     kind = 'emsg',
      --     find = 'Error in decoration provider',
      --   },
      --   opts = { skip = true },
      -- },
    },
  })
end

config.image = function()
  require('image').setup({
    bakcend = 'kitty',
    processor = 'magick_cli',
  })
end

return config
