local group = vim.api.nvim_create_augroup('Dashboard', { clear = true })
local cmd = require('core.keymap').cmd

local function get_color_modules()
  local modules = {}
  -- 获取配置根目录，拼接出绝对路径
  local art_dir = vim.fn.stdpath('config') .. '/lua/internal/util/color_arts'
  -- 扫描所有的 .lua 文件
  local files = vim.fn.globpath(art_dir, '*.lua', false, true)

  for _, file in ipairs(files) do
    -- 提取纯文件名（不含路径和扩展名），例如 "raze-1"
    local name = vim.fn.fnamemodify(file, ':t:r')
    table.insert(modules, 'internal.util.color_arts.' .. name)
  end
  return modules
end

local color_modules = get_color_modules()

local M = {}

local config = {
  shortcuts = {
    { key = 'f', desc = 'Open File', action = cmd('FzfLua files') },
    { key = 'e', desc = 'New File', action = cmd('enew') },
    { key = 'o', desc = 'Recent Files', action = cmd('FzfLua oldfiles') },
    {
      key = 'n',
      desc = 'Nvim Config',
      action = cmd('FzfLua files cwd=~/.config/nvim fd_opts=--type\\ f'),
    },
    -- {
    --   key = 'w',
    --   desc = 'Git Status',
    --   action = cmd('FzfLua git_status'),
    -- }, -- use lazygit instead
    { key = 'm', desc = 'My Agenda', action = cmd('Agenda') },
    { key = 'b', desc = 'Book Marks', action = cmd('lua require("internal.bookmark").show()') },
    {
      key = 'u',
      desc = 'Pack Status',
      action = cmd('PackStatus'),
    },
    { key = 'q', desc = 'Quit', action = cmd('qa') },
  },

  highlights = {
    lambda = 'DashboardLambda',
    key = 'DashboardKey',
    desc = 'DashboardDesc',
    date = 'DashboardDate',
    footer = 'DashboardFooter',
    greeting = 'DashboardGreeting',
  },

  layout = {
    top_offset = 3,
    art_date_gap = 2,
    date_plugin_gap = 1,
    plugin_shortcuts_gap = 2,
    key_desc_spacing = 4,
    shortcuts_greeting_gap = 3,
  },
}

local selected_art = {}

local function center_left(text)
  local width = vim.fn.strdisplaywidth(text)
  return math.max(1, math.floor((vim.o.columns - width) / 2))
end

local function calculate_positions()
  local screen_width = vim.o.columns
  local spacing = string.rep(' ', config.layout.key_desc_spacing)

  local lambda_max_width = 0
  for _, line in ipairs(selected_art) do
    lambda_max_width = math.max(lambda_max_width, vim.fn.strdisplaywidth(line))
  end
  local lambda_left = math.max(1, math.floor((screen_width - lambda_max_width) / 2))

  local shortcuts_max_width = 0
  for _, s in ipairs(config.shortcuts) do
    local text = string.format('[%s]%s%s', s.key, spacing, s.desc)
    shortcuts_max_width = math.max(shortcuts_max_width, vim.fn.strdisplaywidth(text))
  end
  local shortcuts_left = math.max(1, math.floor((screen_width - shortcuts_max_width) / 2))

  local top = config.layout.top_offset
  local lambda_lines = #selected_art
  local date_line = top + lambda_lines + config.layout.art_date_gap
  local plugin_line = date_line + config.layout.date_plugin_gap
  local shortcuts_start = plugin_line + config.layout.plugin_shortcuts_gap

  local shortcuts_end = shortcuts_start + #config.shortcuts - 1
  local greeting_line = shortcuts_end + config.layout.shortcuts_greeting_gap

  return {
    lambda_left = lambda_left,
    shortcuts_left = shortcuts_left,
    date_line = date_line,
    plugin_line = plugin_line,
    shortcuts_start = shortcuts_start,
    greeting_line = greeting_line,
    total_lines = greeting_line,
  }
end

local function setup_highlights()
  local highlights = {
    DashboardLambda = { link = 'Conceal' },
    DashboardKey = { link = 'Constant' },
    DashboardDesc = { link = 'Function' },
    DashboardDate = { link = 'PreProc' },
    DashboardFooter = { link = 'Keyword' },
    DashboardGreeting = { link = 'IndentLineCurrent' },
  }

  for g, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, g, opts)
  end
end

local function get_datetime()
  local datetime = os.date('*t')
  local weekdays = { 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' }
  local months =
    { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' }

  local weekday = weekdays[datetime.wday]
  local year = datetime.year
  local month = months[datetime.month]
  local day = datetime.day
  local hour = string.format('%02d', datetime.hour)
  local min = string.format('%02d', datetime.min)

  return string.format('%s %d %s %d %s:%s', weekday, year, month, day, hour, min)
end

local function create_dashboard_buffer()
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].buflisted = false
  vim.bo[buf].modifiable = false
  return buf
end

local function render_dashboard(buf)
  local lines = {}
  local highlights_to_apply = {}
  local pos = calculate_positions()
  local spacing = string.rep(' ', config.layout.key_desc_spacing)

  for _ = 1, pos.total_lines do
    table.insert(lines, '')
  end

  for i, lambda_line in ipairs(selected_art) do
    local line_idx = config.layout.top_offset + i
    if line_idx <= #lines then
      local offset = pos.lambda_left - 1
      local new_line = string.rep(' ', offset) .. lambda_line
      lines[line_idx] = new_line

      if M.color_hl_map and M.color_hl_map[i] then
        for _, hl_chunk in ipairs(M.color_hl_map[i]) do
          local hl_group = hl_chunk[1]
          local col_start = hl_chunk[2]
          local col_end = hl_chunk[3]

          table.insert(highlights_to_apply, {
            line = line_idx - 1,
            col_start = offset + col_start,
            col_end = offset + col_end,
            hl_group = hl_group,
          })
        end
      else
        local lambda_byte_end = offset + #lambda_line
        table.insert(highlights_to_apply, {
          line = line_idx - 1,
          col_start = offset,
          col_end = lambda_byte_end,
          hl_group = config.highlights.lambda,
        })
      end
    end
  end
  local greeting_str = '就算是开玩笑也请不要这么说'
  local greeting_left = center_left(greeting_str)

  if pos.greeting_line <= #lines then
    local new_line = string.rep(' ', greeting_left - 1) .. greeting_str
    lines[pos.greeting_line] = new_line

    table.insert(highlights_to_apply, {
      line = pos.greeting_line - 1,
      col_start = greeting_left - 1,
      col_end = greeting_left - 1 + #greeting_str,
      hl_group = config.highlights.greeting,
    })
  end

  local datetime_str = get_datetime()
  local date_left = center_left(datetime_str)

  if pos.date_line <= #lines then
    local new_line = string.rep(' ', date_left - 1) .. datetime_str
    lines[pos.date_line] = new_line

    table.insert(highlights_to_apply, {
      line = pos.date_line - 1,
      col_start = date_left - 1,
      col_end = date_left - 1 + #datetime_str,
      hl_group = config.highlights.date,
    })
  end

  local plugins = vim.pack.get(nil, { info = false })
  local rtp_set = {}
  for _, path in ipairs(vim.opt.rtp:get()) do
    rtp_set[path] = true
  end
  local loaded_now = vim
    .iter(plugins)
    :filter(function(p)
      return rtp_set[p.path] ~= nil
    end)
    :totable()
  local startup_time = vim.g.nvim_startup_time or '0'
  local plugin_info_str = string.format(
    'Neovim loaded %d/%d plugins in %sms',
    #loaded_now or 0,
    #plugins or 0,
    startup_time
  )

  local plugin_left = center_left(plugin_info_str)

  if pos.plugin_line <= #lines then
    local new_line = string.rep(' ', plugin_left - 1) .. plugin_info_str
    lines[pos.plugin_line] = new_line

    table.insert(highlights_to_apply, {
      line = pos.plugin_line - 1,
      col_start = plugin_left - 1,
      col_end = plugin_left - 1 + #plugin_info_str,
      hl_group = config.highlights.footer,
    })
  end

  local cursor = {}
  local shortcuts = config.shortcuts

  for i, shortcut in ipairs(shortcuts) do
    local row_idx = pos.shortcuts_start + i - 1
    if row_idx <= #lines then
      local shortcut_text = string.format('[%s]%s%s', shortcut.key, spacing, shortcut.desc)
      local new_line = string.rep(' ', pos.shortcuts_left - 1) .. shortcut_text
      lines[row_idx] = new_line

      if i == 1 then
        cursor[1] = row_idx
        cursor[2] = pos.shortcuts_left + 1
      end

      table.insert(highlights_to_apply, {
        line = row_idx - 1,
        col_start = pos.shortcuts_left,
        col_end = pos.shortcuts_left + 2,
        hl_group = config.highlights.key,
      })

      local desc_start = pos.shortcuts_left + 2 + config.layout.key_desc_spacing
      table.insert(highlights_to_apply, {
        line = row_idx - 1,
        col_start = desc_start,
        col_end = pos.shortcuts_left + #shortcut_text,
        hl_group = config.highlights.desc,
      })
    end
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = 'dashboard'
  vim.bo[buf].modifiable = false

  if cursor[1] and cursor[2] then
    pcall(vim.api.nvim_win_set_cursor, 0, cursor)
  end

  local ns_id = vim.api.nvim_create_namespace('dashboard')
  for _, hl in ipairs(highlights_to_apply) do
    pcall(vim.hl.range, buf, ns_id, hl.hl_group, { hl.line, hl.col_start }, { hl.line, hl.col_end })
  end
end

local function setup_keymaps(buf)
  local opts = { noremap = true, silent = true, buffer = buf } -- 仅在当前缓冲区有效

  for _, shortcut in ipairs(config.shortcuts) do
    vim.keymap.set('n', shortcut.key, shortcut.action, opts)
  end

  vim.keymap.set('n', '<Esc>', ':q<CR>', opts)
  vim.keymap.set('n', 'q', ':q<CR>', opts)
  vim.keymap.set('n', 't', function()
    render_dashboard(buf)
  end, vim.tbl_extend('force', opts, { desc = 'Refresh dashboard' }))
end

local function opt_handler()
  local save_opts = {}

  save_opts.number = vim.wo.number
  save_opts.relativenumber = vim.wo.relativenumber
  save_opts.cursorline = vim.wo.cursorline
  save_opts.cursorcolumn = vim.wo.cursorcolumn
  save_opts.colorcolumn = vim.wo.colorcolumn
  save_opts.signcolumn = vim.wo.signcolumn
  save_opts.wrap = vim.wo.wrap
  save_opts.laststatus = vim.o.laststatus
  save_opts.showtabline = vim.o.showtabline
  save_opts.listchars = vim.o.listchars

  return function()
    vim.wo.number = save_opts.number
    vim.wo.relativenumber = save_opts.relativenumber
    vim.wo.cursorline = save_opts.cursorline
    vim.wo.cursorcolumn = save_opts.cursorcolumn
    vim.wo.colorcolumn = save_opts.colorcolumn
    vim.wo.signcolumn = save_opts.signcolumn
    vim.wo.wrap = save_opts.wrap
    vim.o.laststatus = save_opts.laststatus
    vim.o.showtabline = save_opts.showtabline
    vim.o.listchars = save_opts.listchars
  end
end

function M.show()
  if vim.fn.argc() > 0 or vim.fn.line2byte('$') ~= -1 then
    vim.o.laststatus = 2
    return
  end
  math.randomseed(os.time())
  local chosen_art = {}

  if #color_modules > 0 then
    -- 如果有彩色文件
    local selected_mod_name = color_modules[math.random(#color_modules)]
    local ok, c_art = pcall(require, selected_mod_name)

    if ok and c_art then
      chosen_art = {
        val = c_art.val,
        hl = c_art.opts.hl,
      }
    else
      chosen_art = { val = { 'ERROR: Failed to load ' .. selected_mod_name }, hl = nil }
    end
  else
    chosen_art = { val = { 'NO COLOR ART FOUND IN FOLDER!' }, hl = nil }
  end
  selected_art = chosen_art.val
  M.color_hl_map = chosen_art.hl

  local buf = create_dashboard_buffer()
  vim.api.nvim_set_current_buf(buf)
  render_dashboard(buf)
  setup_highlights()
  setup_keymaps(buf)

  local restore_opt = opt_handler()

  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.cursorline = false
  vim.wo.cursorcolumn = false
  vim.wo.colorcolumn = '0'
  vim.wo.signcolumn = 'no'
  vim.wo.wrap = false
  vim.wo.listchars = 'precedes: '

  vim.o.laststatus = 0
  vim.o.showtabline = 1

  vim.api.nvim_create_autocmd('VimResized', {
    buffer = buf,
    group = group,
    callback = function()
      if vim.bo[buf].filetype == 'dashboard' then
        render_dashboard(buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = buf,
    group = group,
    callback = function()
      restore_opt()
    end,
  })

  vim.schedule(function()
    vim.api.nvim_exec_autocmds('User', { pattern = 'DashboardLoaded', modeline = false })
  end)
end

-- vim.api.nvim_create_autocmd('VimEnter', {
--   group = group,
--   callback = function()
--     if vim.fn.argc() == 0 and vim.fn.line2byte('$') == -1 then
--       M.show()
--     end
--     vim.o.laststatus = 2
--   end,
-- })

vim.api.nvim_create_user_command('Dashboard', function()
  M.show()
end, {})

return M
