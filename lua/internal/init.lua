local au = vim.api.nvim_create_autocmd
local uc = vim.api.nvim_create_user_command
local api = vim.api
local group = vim.api.nvim_create_augroup('ChamomileGroup', {})

------------ auto commands ------------

-- initialization
au('UIEnter', {
  group = group,
  once = true,
  callback = function()
    -- colorscheme
    vim.cmd.colorscheme('gruvbox')

    -- status ui
    require('internal.status')

    -- lsp
    require('internal.lsp')

    -- keymap
    require('keymap')

    -- cursor word
    require('internal.cursor_word')
  end,
})

-- im_switch
au('InsertLeave', {
  group = group,
  callback = function()
    require('internal.im_switch').change_to_en()
  end,
})
au('InsertEnter', {
  group = group,
  pattern = { '*.md', '*.txt' },
  callback = function()
    if require('internal.im_switch').filetype_checke() then
      require('internal.im_switch').change_to_zh()
    end
  end,
})

-- relativenumber toogle insert
au({ 'InsertEnter' }, {
  desc = 'Disable the relative line number when enter insert mode',
  group = group,
  callback = function()
    local buftype = vim.bo.buftype

    if buftype == '' then
      vim.wo.relativenumber = false
    end
  end,
})

au({ 'InsertLeave' }, {
  desc = 'Enable relative line number when leave insert mode',
  group = group,
  callback = function()
    local buftype = vim.bo.buftype

    if buftype == '' then
      vim.wo.relativenumber = true
    end
  end,
})

-- markdown_table_format
au('InsertLeave', {
  group = group,
  pattern = '*.md',
  callback = function()
    require('internal.markdown_table_format').format_markdown_table()
  end,
})

-- auto pairs
au({ 'InsertEnter', 'CmdlineEnter' }, {
  group = group,
  once = true,
  callback = function()
    require('internal.pairs')
  end,
})

-- hlsearch
au('CursorMoved', {
  group = group,
  callback = function()
    require('internal.hlsearch').start_hl()
  end,
})
au('InsertEnter', {
  group = group,
  callback = function()
    require('internal.hlsearch').stop_hl()
  end,
})

au('TermOpen', { group = group, command = 'startinsert' })

au('TextYankPost', {
  group = group,
  callback = function()
    vim.hl.on_yank({ higroup = 'Visual', timeout = 200 })
    if vim.v.event.regname == '+' then
      vim.system({ 'wl-copy' }, { stdin = vim.fn.getreg('+') })
    end
  end,
})

au('BufRead', {
  group = group,
  callback = function()
    vim.cmd.setlocal('formatoptions-=ro')
    -- last plase
    local pos = vim.fn.getpos('\'"')
    if pos[2] > 0 and pos[2] <= vim.fn.line('$') then
      vim.api.nvim_win_set_cursor(0, { pos[2], pos[3] - 1 })
    end
  end,
})

au('LspAttach', {
  group = group,
  callback = function()
    -- work tools
    require('internal.work_tools').wt()
  end,
})

au('BufLeave', {
  group = group,
  callback = function()
    if vim.bo.modified then
      vim.cmd('silent! write')
    end
  end,
})

au('PackChanged', {
  group = group,
  once = true,
  callback = function(ev)
    local name, active, kind = ev.data.spec.name, ev.data.spec.active, ev.data.spec.kind
    if name == 'nvim-treesitter' then
      if not active then
        vim.cmd.packadd(name)
      end
      if kind == 'install' or kind == 'update' then
        require(name).install({
          'bash',
          'c',
          'cpp',
          'go',
          'html',
          'javascript',
          'lua',
          'markdown',
          'markdown_inline',
          'python',
          'typescript',
          'vim',
          'json',
          'vimdoc',
        }, { summary = true })
      end
    end
  end,
})

------------ user commands ------------

-- vim.pack
-- 获取所有已安装插件的名称列表
local function get_plugin_names(arg_lead)
	local installed = vim.pack.get(nil, { info = false })
	local names = {}
	for _, p in ipairs(installed) do
		local name = p.spec.name
		-- 只添加匹配开头字符串的插件
		if name:lower():find(arg_lead:lower(), 1, true) == 1 then
			table.insert(names, name)
		end
	end
	-- 排序让补全列表更整洁
	table.sort(names)
	return names
end

uc('PackUpdate', function(opts)
  local targets = #opts.fargs > 0 and opts.fargs or nil
  local force = opts.bang -- 如果输入了 PackUpdate! 则 opts.bang 为 true
  if targets then
    vim.notify('Checking updates for: ' .. table.concat(targets, ', '), vim.log.levels.INFO)
  else
    vim.notify('Checking updates for all plugins...', vim.log.levels.INFO)
  end
  vim.pack.update(targets, { force = force })
end, {
  nargs = '*',
  bang = true, -- 声明支持 ! 符号
  complete = get_plugin_names,
  desc = 'Update plugins (use ! to skip confirmation)',
})

-- :PackStatus 命令查看插件当前状态和版本
uc('PackStatus', function(opts)
  local targets = #opts.fargs > 0 and opts.fargs or nil
  vim.pack.update(targets, { offline = true })
end, {
  nargs = '*',
  complete = get_plugin_names,
  desc = 'Check plugin status without downloading',
})
uc('PackDelete', function(opts)
  if #opts.fargs == 0 then
    vim.notify("⚠️ Please input the plugin name", vim.log.levels.WARN)
    return
  end

  local targets = opts.fargs
  vim.notify("🗑️ deleting: " .. table.concat(targets, ", "), vim.log.levels.INFO)
  local ok, err = pcall(vim.pack.del, targets)
  if ok then
    vim.notify("✅ delete finished！(restart Neovim to see)", vim.log.levels.INFO)
  else
    vim.notify("❌ delete failed: " .. tostring(err), vim.log.levels.ERROR)
  end
end, {
  nargs = "+", -- 允许传入一个或多个参数 (空格分隔，支持批量删除)
  complete = get_plugin_names,
  desc = "delete the Neovim plugin",
})

-- code_running
uc('Run', function(args)
  require('internal.code_running.code_running').running(args.args)
end, {
  nargs = '?',
  complete = function(arg)
    local list = vim.tbl_extend(
      'force',
      require('internal.code_running.code_running_commands').commands_list(),
      { 'center' }
    )
    return vim.tbl_filter(function(s)
      return string.match(s, '^' .. arg)
    end, list)
  end,
})

-- change directory
uc('Chdir', function(args)
  vim.cmd('silent! lcd %:p:h')
  if args.args == 'silent' then
    return
  end
  vim.notify(('From: %s\nTo: %s'):format(vim.fn.getcwd(), vim.fn.expand('%:p:h')))
end, { nargs = '?' })
