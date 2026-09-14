local api = vim.api
local conf = require('modules.config')
local group = vim.api.nvim_create_augroup('Chamomile.plugin', {})

local specs = {

  {
    'nvimdev/lspsaga.nvim',
    events = { 'BufReadPost', 'BufNewFile', 'User DashboardLoaded' },
    config = conf.lspsaga,
  },

  {
    'saghen/blink.cmp',
    version = vim.version.range('^1'),
    -- version = "main", -- slove the :Man https://github.com/saghen/blink.cmp/issues/2546 Instead use FzfLua manpages
    events = { 'LspAttach', 'InsertEnter', 'CmdlineEnter' },
    config = conf.blink,
    -- dep = {
    --   {"saghen/blink.lib",events = {'LspAttach','BufModifiedSet'},}
    -- }
  },

  {
    'nvim-treesitter/nvim-treesitter',
    version = 'main',
    events = { 'BufReadPre', 'BufNewFile' },
    build = ':TSUpdate',
    config = conf.treesitter,
    dep = {

      {
        'nvim-treesitter/nvim-treesitter-textobjects',
        version = 'main',
        events = { 'BufReadPre' },
      },
    },
  },

  {
    'ibhagwan/fzf-lua',
    events = { 'User DashboardLoaded' },
    cmd = 'FzfLua',
    config = conf.fzflua,
  },

  {
    'nvimdev/guard.nvim',
    cmd = 'Guard',
    config = conf.guard,
  },

  {
    'lewis6991/gitsigns.nvim',
    events = { 'LspAttach', 'BufReadPost', 'User DashboardLoaded' },
    config = conf.gitsigens,
  },

  {
    'nvimdev/indentmini.nvim',
    events = { 'BufReadPre' },
    config = conf.indentmini,
  },
  {
    'folke/noice.nvim',
    events = { 'LspAttach', 'User DashboardLoaded' },
    config = conf.noice,
    dep = {
      { 'MunifTanjim/nui.nvim' },
      { 'rcarriga/nvim-notify' },
    },
  },
  {
    '3rd/image.nvim',
    ft = { 'markdown', 'dashboard' },
    config = conf.image,
  },
}

local function to_url(s)
  return s:match('^https?://') and s or 'https://github.com/' .. s
end

local function to_name(s)
  return s:sub(s:find('/') + 1)
end

local function get_pkg_path(pkg_name)
  local paths = api.nvim_get_runtime_file('pack/*/*/' .. pkg_name, true)
  if #paths > 0 then
    return paths[1]
  end
  local glob = vim.fn.globpath(vim.o.packpath, 'pack/*/*/' .. pkg_name, 0, 1)
  return glob[1] or nil
end

local function run_build(build, pkg_name)
  if not build then
    return
  end

  local pkg_path = get_pkg_path(pkg_name)
  local function finish_build(success)
    if success and pkg_path then
      vim.fn.writefile({}, pkg_path .. '/.build_done')
    end
  end

  if type(build) == 'string' and build:sub(1, 1) == ':' then
    vim.schedule(function()
      vim.cmd.packadd(pkg_name)
      local ok = pcall(vim.cmd, build:sub(2))
      finish_build(ok)
      if not ok then
        vim.notify(('Build failed: %s'):format(pkg_name), vim.log.levels.ERROR)
      end
    end)
  elseif type(build) == 'string' then
    vim.system({ vim.o.shell, '-c', build }, {
      cwd = pkg_path,
    }, function(obj)
      vim.schedule(function()
        finish_build(obj.code == 0)
        if obj.code ~= 0 then
          vim.notify(
            ('Build failed: %s (exit %d)'):format(pkg_name, obj.code),
            vim.log.levels.ERROR
          )
        end
      end)
    end)
  elseif type(build) == 'function' then
    vim.schedule(function()
      vim.cmd.packadd(pkg_name)
      local ok, err = pcall(build)
      finish_build(ok)
      if not ok then
        vim.notify(('Build failed: %s\n%s'):format(pkg_name, err), vim.log.levels.ERROR)
      end
    end)
  end
end

local function load(pkg_name, events, cmd, ft, config)
  if not events and not cmd and not ft then -- directly load without events and cmd and ft
    return false
  end
  return function()
    if events then
      -- 1. 统一转换成数组，方便后续统一遍历 (应对传单字符串和传数组两种情况)
      if type(events) == 'string' then
        events = { events }
      end

      local standard_events = {}

      -- 2. 遍历事件列表，分流处理
      for _, ev in ipairs(events) do
        if type(ev) == 'string' and ev:match('^User%s') then
          -- 处理 User 事件 (提取 pattern)
          local pattern_name = ev:sub(6)
          api.nvim_create_autocmd('User', {
            pattern = pattern_name,
            group = group,
            once = true,
            callback = function()
              vim.cmd.packadd(pkg_name)
              if config then
                config()
              end
            end,
          })
        else
          -- 收集原生事件
          table.insert(standard_events, ev)
        end
      end

      -- 3. 如果有原生事件，统一注册
      if #standard_events > 0 then
        api.nvim_create_autocmd(standard_events, {
          group = group,
          once = true,
          callback = function()
            vim.cmd.packadd(pkg_name)
            if config then
              config()
            end
          end,
        })
      end
    end
    if cmd then
      if type(cmd) == 'string' then
        cmd = { cmd }
      end
      for _, c in ipairs(cmd) do
        api.nvim_create_user_command(c, function(data)
          api.nvim_del_user_command(c)
          vim.cmd.packadd(pkg_name)
          if config then
            config()
          end
          local bang = data.bang and '!' or ''
          vim.cmd(('%s%s %s'):format(c, bang, data.args))
        end, { nargs = '*', bang = true })
      end
    end

    if ft then
      if type(ft) == 'string' then
        ft = { ft }
      end
      api.nvim_create_autocmd('FileType', {
        pattern = ft,
        group = group,
        once = true,
        callback = function()
          vim.cmd.packadd(pkg_name)
          if config then
            config()
          end
        end,
      })
    end
  end
end

local function get_pack_info(info, version)
  local pkg_name = to_name(info)
  local pkg_url
  if version then
    pkg_url = { {
      src = to_url(info),
      version = version,
    } }
  else
    pkg_url = { to_url(info) }
  end
  return pkg_name, pkg_url
end

local function packadd(info)
  local pkg_name, pkg_url = get_pack_info(info[1], info.version)

  local pkg_path = get_pkg_path(pkg_name)
  local already_built = pkg_path and vim.loop.fs_stat(pkg_path .. '/.build_done') ~= nil
  vim.pack.add(
    pkg_url,
    vim.tbl_extend(
      'keep',
      { load = load(pkg_name, info.events, info.cmd, info.ft, info.config) },
      { confirm = false }
    )
  )
  if not info.events and not info.cmd and not info.ft then
    local ok, _ = pcall(vim.cmd.packadd, pkg_name)
    if ok and info.config then
      info.config()
    end
  end

  if not already_built and info.build then
    -- print(('Building: %s'):format(pkg_name))
    vim.schedule(function()
      run_build(info.build, pkg_name)
    end)
  end
end

for _, plugin in ipairs(specs) do
  if plugin.enabled ~= false then -- set the enabled to false to disable  the plugin
    if plugin.dep then
      -- vim.notify(string.format("dep:%s",#plugin.dep))
      for i = 1, #plugin.dep do
        packadd(plugin.dep[i])
      end
    end
    packadd(plugin)
  end
end
