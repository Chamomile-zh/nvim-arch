require('keymap.remap')
local map = require('core.keymap')
local cmd = map.cmd
local api = vim.api

map.n({
  -- fzflua
  ['<leader>ff'] = cmd('FzfLua files'),
  ['<leader>fw'] = cmd('FzfLua live_grep'),
  ['<leader>fh'] = cmd('FzfLua helptags'),
  ['<leader>fo'] = cmd('FzfLua oldfiles'),
  ['<leader>fb'] = cmd('FzfLua buffers'),
  ['<leader>fk'] = cmd('FzfLua keymaps'),
  -- lspsaga
  ['<leader>pd'] = cmd('Lspsaga peek_definition'),
  ['<leader>pr'] = cmd('Lspsaga finder ref'),
  ['<Leader>dw'] = cmd('Lspsaga show_workspace_diagnostics'),
  ['<Leader>db'] = cmd('Lspsaga show_buf_diagnostics'),
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
  ['<leader>iw'] = function ()
    require("internal.invert_word").inver_word()
  end,

  -- jump
  ['f'] = function ()
    local j = require('internal.jump')
    if j.charForward then
      j.charForward()
    end
  end,
  ['F'] = function ()
    local j = require('internal.jump')
    if j.charBackward then
      j.charBackward()
    end
  end
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
  local bufnr = api.nvim_create_buf(false, false)
  vim.bo[bufnr].buftype = 'prompt'
  vim.fn.prompt_setprompt(bufnr, ' ')
  api.nvim_buf_set_extmark(bufnr, api.nvim_create_namespace('WebSearch'), 0, 0, {
    line_hl_group = 'String',
  })
  local width = math.floor(vim.o.columns * 0.5)
  local winid = api.nvim_open_win(bufnr, true, {
    relative = 'editor',
    row = 5,
    width = width,
    height = 5,
    col = math.floor(vim.o.columns / 2) - math.floor(width / 2),
    border = 'rounded',
    title = 'cn.bing Search',
    title_pos = 'center',
  })
  vim.cmd.startinsert()
  vim.wo[winid].number = false
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
