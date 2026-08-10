local co, api, iter = coroutine, vim.api, vim.iter

local function stl_format(name, val)
  return '%#Status' .. name .. '#' .. val .. '%*'
end

local function default()
  local p = require('internal.status.stl')
  local comps = {
    --left
    p.sep(),
    p.mode(),
    p.sepl(),
    p.fileinfo(),
    p.modified(),
    p.readonly(),
    p.sepl(),
    p.gitinfo('head'),
    p.gitinfo('added'),
    p.gitinfo('changed'),
    p.gitinfo('removed'),
    --center
    p.pad(),
    p.progress(),
    p.lsp(),
    p.pad(),
    --right
    -- p.search(),
    p.diagnostic(vim.diagnostic.severity.E),
    p.diagnostic(vim.diagnostic.severity.W),
    p.diagnostic(vim.diagnostic.severity.I),
    p.diagnostic(vim.diagnostic.severity.N),
    p.recording(),
    p.vnumber(),
    p.sepr(),
    p.filetype(),
    p.sepr(),
    p.filesize(),
    p.sepr(),
    p.encoding(),
    p.sepr(),
    p.lnumcol(),
    p.sep(),
  }

  local e, pieces = {}, {}
  iter(ipairs(comps))
    :map(function(key, item)
      if type(item) == 'string' then
        pieces[#pieces + 1] = stl_format('Padding', item)
      elseif type(item.stl) == 'string' then
        pieces[#pieces + 1] = stl_format(item.name, item.stl)
      else
        pieces[#pieces + 1] = item.default and stl_format(item.name, item.default) or ''
        for _, event in ipairs({ unpack(item.event or {}) }) do
          if not e[event] then
            e[event] = {}
          end
          e[event][#e[event] + 1] = key
        end
      end
      if item.attr and item.name then
        api.nvim_set_hl(0, ('Status%s'):format(item.name), item.attr)
      end
    end)
    :totable()

  return comps, e, pieces
end

local function render(comps, events, pieces)
  return co.create(function(args)
    while true do
      local event = args.event == 'User' and args.event .. ' ' .. args.match or args.event
      -- 只更新触发事件对应的组件，而非全量重绘
      for _, idx in ipairs(events[event] or {}) do
        local comp = comps[idx]
        if type(comp.stl) == 'function' then
          pieces[idx] = stl_format(comp.name, comp.stl(args))
        end
      end
      vim.opt.stl = table.concat(pieces)
      args = coroutine.yield()
    end
  end)
end

vim.defer_fn(function()
  -- 状态列
  vim.opt.stc = '%!v:lua.require("internal.status.stc").stc()'

  -- 状态栏初始化
  local comps, events, pieces = default()
  local stl_render = render(comps, events, pieces)

  -- 窗口切换事件：全量重绘，更新活动/非活动样式
  local win_events = { 'WinEnter', 'WinLeave', 'BufWinEnter' }
  for _, ev in ipairs(win_events) do
    if not events[ev] then
      events[ev] = {}
    end
    -- 窗口切换时全量重绘所有组件
    for i = 1, #comps do
      table.insert(events[ev], i)
    end
  end

  -- 注册所有事件监听
  for event, _ in pairs(events) do
    local pattern = nil
    local event_name = event
    if event:find('^User ') then
      event_name = 'User'
      pattern = vim.split(event, '%s')[2]
    end

    api.nvim_create_autocmd(event_name, {
      pattern = pattern,
      callback = function(args)
        vim.schedule(function()
          local ok, err = coroutine.resume(stl_render, args)
          if not ok then
            vim.notify('[StatusLine] render failed: ' .. err, vim.log.levels.ERROR)
          end
        end)
      end,
    })
  end
end, 0)
