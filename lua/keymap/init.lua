require('keymap.remap')
local map = require('core.keymap')
local cmd = map.cmd
local api = vim.api

map.n({
  -- fzflua
  ['<Leader>d'] = cmd('FzfLua diagnostics_document'),
  ['<Leader>D'] = cmd('FzfLua diagnostics_workspace'),
  ['<leader>ff'] = function()
    local workspace_folders = vim.lsp.buf.list_workspace_folders()
    local root = workspace_folders[1] or vim.fn.getcwd()

    vim.cmd(('FzfLua files cwd=%s'):format(vim.fn.fnameescape(root)))
  end,
  ['<leader>fw'] = function()
    local workspace_folders = vim.lsp.buf.list_workspace_folders()
    local root = workspace_folders[1] or vim.fn.getcwd()

    vim.cmd(('FzfLua live_grep_native cwd=%s'):format(vim.fn.fnameescape(root)))
  end,
  ['<leader>fh'] = cmd('FzfLua helptags'),
  ['<leader>fo'] = cmd('FzfLua oldfiles'),
  ['<leader>b'] = cmd('FzfLua buffers'),
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
      vim.notify('Directory not found：' .. target_dir, vim.log.levels.ERROR)
      return
    end
    vim.cmd(('FzfLua files cwd=%s'):format(target_dir))
  end,
  -- noice
  ['<leader>n'] = function()
    if not package.loaded['fzf-lua'] then
      vim.cmd.packadd('fzf-lua')
    end
    vim.cmd('Noice fzf')
  end, -- need to load the Fzflua


  -- Shell
  ['<A-x>'] = cmd('Shell'),

  --todo
  ['<leader>td'] = function()
    require('internal.todo').fzf_todo(true)
  end,

  ['<leader>tD'] = function()
    require('internal.todo').fzf_todo(false)
  end,
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
  ['<leader>lg'] = function()
    require('internal.lazygit').lazygit()
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
  ['<A-t>'] = function()
    require('internal.toggle_term').toggle_term()
  end,
  ['<A-f>'] = function()
    require('internal.toggle_term').toggle_term('focus')
  end,
  ['<A-m>'] = function()
    if vim.bo.buftype == 'terminal' then
      vim.cmd('startinsert')
    end
  end,
  --invert word
  ['<leader>iw'] = function()
    require('internal.invert_word').inver_word()
  end,

  -- template
  ['<leader>tm'] = cmd('Template'),
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

-- toggle_term
map.t({
  ['<A-t>'] = {
    rhs = function()
      require('internal.toggle_term').toggle_term()
    end,
    desc = 'Toggle terminal window',
  },
  ['<A-r>'] = {
    rhs = function()
      require('internal.toggle_term').toggle_term('pos')
    end,
    desc = 'Toggle terminal position',
  },
  ['<A-f>'] = {
    rhs = function()
      require('internal.toggle_term').toggle_term('focus')
    end,
    desc = 'Focus terminal window',
  },
  ['<A-q>'] = {
    rhs = function()
      require('internal.toggle_term').toggle_term('kill')
    end,
    desc = 'Kill terminal process',
  },
  ['<A-m>'] = {
    rhs = '<C-\\><C-n>',
    desc = 'Exit terminal insert mode',
  },
})

map.v({
  -- surround
  ['S'] = function()
    require('internal.surround').surround('add')
  end,
})

map.nxo({
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
  -- jump
  ['f'] = {
    rhs = function()
      local j = require('internal.jump')
      if j.charForward then
        j.charForward()
      end
    end,
    desc = 'jump to the character with a letter',
  },
  ['F'] = function()
    local j = require('internal.jump')
    if j.charBackward then
      j.charBackward()
    end
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

-- remove comment
map.x('<leader>rc', function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
  vim.schedule(function()
    local buf = vim.api.nvim_get_current_buf()
    local sr = vim.fn.line("'<") - 1
    local er = vim.fn.line("'>") - 1

    local ok, parser = pcall(vim.treesitter.get_parser, buf)
    if not ok or not parser then
      print('not supported')
      return
    end
    local tree = parser:parse()[1]
    if not tree then
      return
    end
    local root = tree:root()
    local nodes_to_delete = {}
    local function find_comments(node)
      if not node then
        return
      end
      local n_sr, n_sc, n_er, n_ec = node:range()
      if n_sr > er or n_er < sr then
        return
      end
      if node:type():lower():find('comment') then
        if n_sr >= sr and n_er <= er then
          table.insert(nodes_to_delete, { n_sr, n_sc, n_er, n_ec })
        end
        return
      end
      for child in node:iter_children() do
        find_comments(child)
      end
    end
    find_comments(root)
    table.sort(nodes_to_delete, function(a, b)
      if a[1] == b[1] then
        return a[2] > b[2]
      end
      return a[1] > b[1]
    end)
    for _, range in ipairs(nodes_to_delete) do
      pcall(vim.api.nvim_buf_set_text, buf, range[1], range[2], range[3], range[4], { '' })
    end
  end)
end)

local function web_search(text)
  text = vim.trim(text or '')

  if text == '' then
    return
  end

  local query = vim.uri_encode(text, 'rfc3986')
  local url = ('https://cn.bing.com/search?q=%s'):format(query)

  local _, err = vim.ui.open(url)

  if err then
    vim.notify(
      'Failed to open Bing: ' .. err,
      vim.log.levels.ERROR
    )
  end
end

-- Search word under cursor
map.n('gX', function()
  web_search(vim.fn.expand('<cword>'))
end, {
  desc = 'Search word with Bing',
})

-- Search visual selection
map.x('gX', function()
  local lines = vim.fn.getregion(
    vim.fn.getpos('.'),
    vim.fn.getpos('v'),
    {
      type = vim.fn.mode(),
    }
  )

  web_search(
    table.concat(lines, ' ')
  )

  api.nvim_input('<Esc>')
end, {
  desc = 'Search selection with Bing',
})

-- Search input
map.n('gs', function()
  vim.ui.input({
    prompt = 'Bing Search',
    scope = 'editor',
  }, function(input)
    if input then
      web_search(input)
    end
  end)
end, {
  desc = 'Search Bing',
})
