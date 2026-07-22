require('keymap.remap')
local map = require('core.keymap')
local cmd = map.cmd
local api = vim.api

map.n({
  -- fzflua
  ['<Leader>d'] = cmd('FzfLua diagnostics_document'),
  ['<Leader>D'] = cmd('FzfLua diagnostics_workspace'),
  ['<leader>ff'] = cmd('FzfLua files'),
  ['<leader>fw'] = cmd('FzfLua live_grep_native'),
  ['<leader>fh'] = cmd('FzfLua helptags'),
  ['<leader>fo'] = cmd('FzfLua oldfiles'),
  ['<leader>fb'] = cmd('FzfLua buffers'),
  ['<leader>fk'] = cmd('FzfLua keymaps'),
  ['<leader>fm'] = cmd('FzfLua manpages'),
  ['<Leader>o'] = cmd('FzfLua lsp_document_symbols'),
  ['<leader>fd'] = function()
    local input_path = vim.fn.input('Search directory: ', '', 'dir')
    if input_path == '' then
      return
    end
    local target_dir = vim.fn.expand(input_path)
    if vim.fn.isdirectory(target_dir) == 0 then
      vim.notify('路径不存在或不是文件夹：' .. target_dir, vim.log.levels.ERROR)
      return
    end
    if not package.loaded['fzf-lua'] then
      vim.cmd.packadd('fzf-lua')
    end
    require('fzf-lua').files({
      cwd = target_dir,
      cwd_prompt = true,
    })
  end,
  -- noice
  ['<leader>n'] = function()
    if not package.loaded['fzf-lua'] then
      vim.cmd.packadd('fzf-lua')
    end
    vim.cmd('Noice fzf')
  end, -- need to load the Fzflua
  -- lspsaga
  ['<leader>pd'] = cmd('Lspsaga peek_definition'),
  ['<leader>gp'] = cmd('Lspsaga goto_definition'),
  ['<leader>gh'] = cmd('Lspsaga finder'),
  ['<leader>pr'] = cmd('Lspsaga finder ref'),
  -- ['<Leader>dw'] = cmd('Lspsaga show_workspace_diagnostics'),
  -- ['<Leader>db'] = cmd('Lspsaga show_buf_diagnostics'),
  ['<leader>K'] = cmd('Lspsaga hover_doc'),
  ['<leader>rn'] = cmd('Lspsaga rename'),
  ['<leader>ca'] = cmd('Lspsaga code_action'),
  ['d['] = cmd('Lspsaga diagnostic_jump_prev'),
  ['d]'] = cmd('Lspsaga diagnostic_jump_next'),
  -- gitsigns
  ['g['] = function()
    require('gitsigns').nav_hunk('prev', { wrap = true })
  end,
  ['g]'] = function()
    require('gitsigns').nav_hunk('next', { wrap = true })
  end,
  ['<leader>H'] = function()
    require('gitsigns').preview_hunk_inline()
  end,
  ['<leader>gd'] = function()
    require('gitsigns').diffthis('~')
  end,
  ['<leader>gr'] = function()
    require('gitsigns').reset_hunk()
  end,
  -- code_running
  ['<F5>'] = cmd('Run'),
  ['<F10>'] = cmd('Run center'),
  ['<F6>'] = cmd('Build'), -- 默认悬浮小窗看编译状态
  ['<F11>'] = cmd('Build center'), -- 居中大窗看复杂编译日志
  -- yazi
  ['<leader>ra'] = function()
    require('internal.yazi').yazi('edit')
  end,
  -- wiki
  ['<leader>ww'] = function()
    require('internal.wiki').open_wiki()
  end,
  -- surround
  ['cs'] = function()
    require('internal.surround').surround('change')
  end,
  ['rs'] = function()
    require('internal.surround').surround('remove')
  end,
  -- toggle term
  ['<c-f>'] = function()
    require('internal.toggle_term').toggle_term()
  end,
  --invert word
  ['<leader>iw'] = function()
    require('internal.invert_word').inver_word()
  end,

  -- jump
  ['f'] = function()
    local j = require('internal.jump')
    if j.charForward then
      j.charForward()
    end
  end,
  ['F'] = function()
    local j = require('internal.jump')
    if j.charBackward then
      j.charBackward()
    end
  end,
})

-- noice
map.nis({
  ['<c-n>'] = function()
    if not require('noice.lsp').scroll(4) then
      return '<c-f>'
    end
  end,
  ['<c-b>'] = function()
    if not require('noice.lsp').scroll(-4) then
      return '<c-b>'
    end
  end,
})

map.t({
  -- toggle term
  ['<c-f>'] = function()
    require('internal.toggle_term').toggle_term()
  end,
  ['<c-r>'] = function()
    require('internal.toggle_term').toggle_term('pos')
  end,
})

map.v({
  -- surround
  ['S'] = function()
    require('internal.surround').surround('add')
  end,
})

map.nx({
  -- guard
  [';f'] = cmd('Guard fmt'),
  --  quick_substitute
  ['<leader>ss'] = function()
    require('internal.quick_substitute').quick_substitute()
  end,
  -- wildfire
  ['<cr>'] = function()
    require('internal.wildfire').wildfire()
  end,
})

map.ni({
  ['<c-t>'] = function()
    require('internal.toggle_mark').toggle_mark()
  end,
})

map.xo({
  ['if'] = function()
    require('nvim-treesitter-textobjects.select').select_textobject(
      '@function.inner',
      'textobjects'
    )
  end,
  ['af'] = function()
    require('nvim-treesitter-textobjects.select').select_textobject(
      '@function.outer',
      'textobjects'
    )
  end,
  ['ic'] = function()
    require('nvim-treesitter-textobjects.select').select_textobject('@class.inner', 'textobjects')
  end,
  ['ac'] = function()
    require('nvim-treesitter-textobjects.select').select_textobject('@class.outer', 'textobjects')
  end,
  ['as'] = function()
    require('nvim-treesitter-textobjects.select').select_textobject('@local.scope', 'locals')
  end,
})

-- gX: Web search
map.n('gX', function()
  vim.ui.open(('https://cn.bing.com/search?q=%s'):format(vim.fn.expand('<cword>')))
end)

map.x('gX', function()
  local lines = vim.fn.getregion(vim.fn.getpos('.'), vim.fn.getpos('v'), { type = vim.fn.mode() })
  vim.ui.open(('https://cn.bing.com/search?q=%s'):format(vim.trim(table.concat(lines, ' '))))
  api.nvim_input('<esc>')
end)

map.n('gs', function()
  local bufnr = api.nvim_create_buf(false, false) -- false代表可编辑，false代表不是scratch临时缓冲区，支持prompt输入回调
  vim.bo[bufnr].buftype = 'prompt' -- 缓冲区类型为prompt交互
  vim.fn.prompt_setprompt(bufnr, ' ') -- 输入框最前面显示的文字
  -- 独立高亮命名空间
  api.nvim_buf_set_extmark(bufnr, api.nvim_create_namespace('WebSearch'), 0, 0, {
    line_hl_group = 'String',
  })
  local width = math.floor(vim.o.columns * 0.5) -- 弹窗宽度
  local winid = api.nvim_open_win(bufnr, true, { -- 打开悬浮窗口 绑定刚刚的bufnr缓冲区
    relative = 'editor', -- 相对于整个编辑器窗口定位
    row = 5, -- 距离编辑器顶部5行
    width = width,
    height = 5, -- 弹窗5行高度
    col = math.floor(vim.o.columns / 2) - math.floor(width / 2), -- 居中
    border = 'rounded', -- 圆角边框
    title = 'Bing Search', -- 标题
    title_pos = 'center', -- 标题居中
  })
  vim.cmd.startinsert() -- 自动进入插入模式
  vim.wo[winid].number = false -- 关闭状态列
  vim.wo[winid].stc = ''
  vim.wo[winid].lcs = 'trail: '
  vim.wo[winid].wrap = true
  vim.wo[winid].signcolumn = 'no'
  vim.fn.prompt_setcallback(bufnr, function(text)
    vim.ui.open(('https://cn.bing.com/search?q=%s'):format(vim.trim(text)))
    api.nvim_win_close(winid, true)
  end)
  vim.keymap.set({ 'n', 'i' }, '<C-c>', function()
    pcall(api.nvim_win_close, winid, true)
  end, { buf = bufnr })
end)
