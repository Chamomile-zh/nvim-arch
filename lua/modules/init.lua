local api = vim.api
local conf = require('modules.config')

local specs = {

  {
    'nvimdev/lspsaga.nvim',
    -- events = {'BufReadPost','BufNewFile'},
    events  = 'LspAttach',
    config = conf.lspsaga,
  },

  {
    'saghen/blink.cmp',
    version = vim.version.range('^1'),
    events = 'LspAttach',
    config = conf.blink,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    version = 'main',
    events = { 'BufReadPre', 'BufNewFile' },
    config = conf.treesitter,
  },

  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    version = 'main',
  },

  {
    'ibhagwan/fzf-lua',
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
    events = 'BufRead',
    config = conf.gitsigens,
  },

  {
    'nvimdev/indentmini.nvim',
    events = 'BufReadPre',
    config = conf.indentmini,
  },
}

local function to_url(s)
  return s:match('^https?://') and s or 'https://github.com/' .. s
end

local function to_name(s)
  return s:sub(s:find('/') + 1)
end

local function get_root()
  local name = 'fzf-lua'
  local paths = api.nvim_get_runtime_file('pack/*/*/' .. name, true)
  if #paths > 0 then
    return paths[1]
  end
  local glob = vim.fn.globpath(vim.o.packpath, 'pack/*/*/' .. name, 0, 1)
  return glob[1] or nil
end

local function load(pkg_name, events, cmd, config)
  if not config then -- disable the plugin by not set the config
    return false
  end
  return function()
    if events then
      api.nvim_create_autocmd(events, {
        once = true,
        callback = function()
          vim.cmd.packadd(pkg_name)
          if config then
            config()
          end
        end,
      })
    end
    if cmd then
      api.nvim_create_user_command(cmd, function(data)
        api.nvim_del_user_command(cmd)
        vim.cmd.packadd(pkg_name)
        if config then
          config()
        end
        vim.cmd(('%s %s'):format(cmd, data.args))
      end, { nargs = '?' })
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
  vim.pack.add(
    pkg_url,
    vim.tbl_extend(
      'keep',
      { load = load(pkg_name, info.events, info.cmd, info.config) } or {},
      { confirm = false }
    )
  )
end

for _, plugin in ipairs(specs) do
  packadd(plugin)
end
