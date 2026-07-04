local group = vim.api.nvim_create_augroup('Dashboard', { clear = true })

local M = {}

local config = {
  lambda_art = {
    '⣿⠟⣽⣿⣿⣿⣿⣿⢣⠟⠋⡜⠄⢸⣿⣿⡟⣬⢁⠠⠁⣤⠄⢰⠄⠇⢻⢸',
    '⢏⣾⣿⣿⣿⠿⣟⢁⡴⡀⡜⣠⣶⢸⣿⣿⢃⡇⠂⢁⣶⣦⣅⠈⠇⠄⢸⢸',
    '⣹⣿⣿⣿⡗⣾⡟⡜⣵⠃⣴⣿⣿⢸⣿⣿⢸⠘⢰⣿⣿⣿⣿⡀⢱⠄⠨⢸',
    '⣿⣿⣿⣿⡇⣿⢁⣾⣿⣾⣿⣿⣿⣿⣸⣿⡎⠐⠒⠚⠛⠛⠿⢧⠄⠄⢠⣼',
    '⣿⣿⣿⣿⠃⠿⢸⡿⠭⠭⢽⣿⣿⣿⢂⣿⠃⣤⠄⠄⠄⠄⠄⠄⠄⠄⣿⡾',
    '⣼⠏⣿⡏⠄⠄⢠⣤⣶⣶⣾⣿⣿⣟⣾⣾⣼⣿⠒⠄⠄⠄⡠⣴⡄⢠⣿⣵',
    '⣳⠄⣿⠄⠄⢣⠸⣹⣿⡟⣻⣿⣿⣿⣿⣿⣿⡿⡻⡖⠦⢤⣔⣯⡅⣼⡿⣹',
    '⡿⣼⢸⠄⠄⣷⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣕⡜⡌⡝⡸⠙⣼⠟⢱⠏',
    '⡇⣿⣧⡰⡄⣿⣿⣿⣿⡿⠿⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣋⣪⣥⢠⠏⠄',
    '⣧⢻⣿⣷⣧⢻⣿⣿⣿⡇⠄⢀⣀⣀⡙⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠂⠄⠄',
    '⢹⣼⣿⣿⣿⣧⡻⣿⣿⣇⣴⣿⣿⣿⣷⢸⣿⣿⣿⣿⣿⣿⣿⣿⣰⠄⠄⠄',
    '⣼⡟⡟⣿⢸⣿⣿⣝⢿⣿⣾⣿⣿⣿⢟⣾⣿⣿⣿⣿⣿⣿⣿⣿⠟⠄⡀⡀',
    '⣿⢰⣿⢹⢸⣿⣿⣿⣷⣝⢿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠛⠉⠄⠄⣸⢰⡇',
    '⣿⣾⣹⣏⢸⣿⣿⣿⣿⣿⣷⣍⡻⣛⣛⣛⡉⠁⠄⠄⠄⠄⠄⠄⢀⢇⡏⠄',

    -- '        ⢀⣴⡾⠃⠄⠄⠄⠄⠄⠈⠺⠟⠛⠛⠛⠛⠻⢿⣿⣿⣿⣿⣶⣤⡀  ',
    -- '      ⢀⣴⣿⡿⠁⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⣸⣿⣿⣿⣿⣿⣿⣿⣷ ',
    -- '     ⣴⣿⡿⡟⡼⢹⣷⢲⡶⣖⣾⣶⢄⠄⠄⠄⠄⠄⢀⣼⣿⢿⣿⣿⣿⣿⣿⣿⣿ ',
    -- '    ⣾⣿⡟⣾⡸⢠⡿⢳⡿⠍⣼⣿⢏⣿⣷⢄⡀⠄⢠⣾⢻⣿⣸⣿⣿⣿⣿⣿⣿⣿ ',
    -- '  ⣡⣿⣿⡟⡼⡁⠁⣰⠂⡾⠉⢨⣿⠃⣿⡿⠍⣾⣟⢤⣿⢇⣿⢇⣿⣿⢿⣿⣿⣿⣿⣿ ',
    -- ' ⣱⣿⣿⡟⡐⣰⣧⡷⣿⣴⣧⣤⣼⣯⢸⡿⠁⣰⠟⢀⣼⠏⣲⠏⢸⣿⡟⣿⣿⣿⣿⣿⣿ ',
    -- ' ⣿⣿⡟⠁⠄⠟⣁⠄⢡⣿⣿⣿⣿⣿⣿⣦⣼⢟⢀⡼⠃⡹⠃⡀⢸⡿⢸⣿⣿⣿⣿⣿⡟ ',
    -- ' ⣿⣿⠃⠄⢀⣾⠋⠓⢰⣿⣿⣿⣿⣿⣿⠿⣿⣿⣾⣅⢔⣕⡇⡇⡼⢁⣿⣿⣿⣿⣿⣿⢣ ',
    -- ' ⣿⡟⠄⠄⣾⣇⠷⣢⣿⣿⣿⣿⣿⣿⣿⣭⣀⡈⠙⢿⣿⣿⡇⡧⢁⣾⣿⣿⣿⣿⣿⢏⣾ ',
    -- ' ⣿⡇⠄⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⢻⠇⠄⠄⢿⣿⡇⢡⣾⣿⣿⣿⣿⣿⣏⣼⣿ ',
    -- ' ⣿⣷⢰⣿⣿⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⢰⣧⣀⡄⢀⠘⡿⣰⣿⣿⣿⣿⣿⣿⠟⣼⣿⣿ ',
    -- ' ⢹⣿⢸⣿⣿⠟⠻⢿⣿⣿⣿⣿⣿⣿⣿⣶⣭⣉⣤⣿⢈⣼⣿⣿⣿⣿⣿⣿⠏⣾⣹⣿⣿ ',
    -- ' ⢸⠇⡜⣿⡟⠄⠄⠄⠈⠙⣿⣿⣿⣿⣿⣿⣿⣿⠟⣱⣻⣿⣿⣿⣿⣿⠟⠁⢳⠃⣿⣿⣿ ',
    -- '  ⣰⡗⠹⣿⣄⠄⠄⠄⢀⣿⣿⣿⣿⣿⣿⠟⣅⣥⣿⣿⣿⣿⠿⠋  ⣾⡌⢠⣿⡿⠃ ',
    -- ' ⠜⠋⢠⣷⢻⣿⣿⣶⣾⣿⣿⣿⣿⠿⣛⣥⣾⣿⠿⠟⠛⠉            ',
  },
  shortcuts = {
    { key = 'f', desc = 'Open File', action = '<cmd>FzfLua files<CR>' },
    { key = 'o', desc = 'Recent Files', action = '<cmd>FzfLua oldfiles<CR>' },
    {
      key = 'd',
      desc = 'Dotfiles',
      action = '<cmd>:FzfLua files cwd=~/.config fd_opts=--type\\ f<CR>',
    },
    {
      key = 'n',
      desc = 'Nvim config',
      action = '<cmd>edit $MYVIMRC | Chdir silent<CR>',
    },
    { key = 'e', desc = 'New File', action = '<cmd>enew<CR>' },
    {
      key = 'u',
      desc = 'Pack Status',
      action = '<cmd>:PackStatus<CR>',
    },
    { key = 'q', desc = 'Quit', action = '<cmd>qa<CR>' },
  },

  highlights = {
    lambda = 'DashboardLambda',
    key = 'DashboardKey',
    desc = 'DashboardDesc',
    date = 'DashboardDate',
    footer = 'DashboardFooter',
  },

  layout = {
    top_offset = 6,
    art_date_gap = 2,
    date_plugin_gap = 1,
    plugin_shortcuts_gap = 2,
    key_desc_spacing = 4,
  },
}

-- 辅助函数：计算文本水平居中的左偏移列数
local function center_left(text)
  local width = vim.fn.strdisplaywidth(text)
  return math.max(1, math.floor((vim.o.columns - width) / 2))
end

local function calculate_positions()
  local screen_width = vim.o.columns
  local spacing = string.rep(' ', config.layout.key_desc_spacing)

  --  图案居中
  local lambda_max_width = 0
  for _, line in ipairs(config.lambda_art) do
    lambda_max_width = math.max(lambda_max_width, vim.fn.strdisplaywidth(line))
  end
  local lambda_left = math.max(1, math.floor((screen_width - lambda_max_width) / 2))

  -- 快捷方式整体居中（按最长一行计算）
  local shortcuts_max_width = 0
  for _, s in ipairs(config.shortcuts) do
    local text = string.format('[%s]%s%s', s.key, spacing, s.desc)
    shortcuts_max_width = math.max(shortcuts_max_width, vim.fn.strdisplaywidth(text))
  end
  local shortcuts_left = math.max(1, math.floor((screen_width - shortcuts_max_width) / 2))

  -- 垂直行号计算
  local top = config.layout.top_offset
  local lambda_lines = #config.lambda_art
  local date_line = top + lambda_lines + config.layout.art_date_gap
  local plugin_line = date_line + config.layout.date_plugin_gap
  local shortcuts_start = plugin_line + config.layout.plugin_shortcuts_gap

  return {
    lambda_left = lambda_left,
    shortcuts_left = shortcuts_left,
    date_line = date_line,
    plugin_line = plugin_line,
    shortcuts_start = shortcuts_start,
    total_lines = shortcuts_start + #config.shortcuts,
  }
end

local function setup_highlights()
  local highlights = {
    DashboardLambda = { link = 'Conceal' },
    DashboardKey = { link = 'Constant' },
    DashboardDesc = { link = 'Function' },
    DashboardDate = { link = 'PreProc' },
    DashboardFooter = { link = 'Keyword' },
  }

  for g, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, g, opts)
  end
end

local function get_datetime()
  local datetime = os.date('*t')
  local weekdays = { 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' }
  local months =
    { 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec' }

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

  for i, lambda_line in ipairs(config.lambda_art) do
    local line_idx = config.layout.top_offset + i
    if line_idx <= #lines then
      local new_line = string.rep(' ', pos.lambda_left - 1) .. lambda_line
      lines[line_idx] = new_line

      local lambda_byte_start = pos.lambda_left - 1
      local lambda_byte_end = lambda_byte_start + #lambda_line
      table.insert(highlights_to_apply, {
        line = line_idx - 1,
        col_start = lambda_byte_start,
        col_end = lambda_byte_end,
        hl_group = config.highlights.lambda,
      })
    end
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

  local plugins = vim.pack.get()
  local loaded = vim
    .iter(plugins)
    :map(function(p)
      return p.active
    end)
    :totable()
  local startup_time = vim.g.nvim_startup_time or '0'
  local plugin_info_str =
    string.format('load %d/%d plugins in %sms', #loaded or 0, #plugins or 0, startup_time)

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

  -- 4. 快捷方式（整体块居中，内部左对齐）
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

      -- 按键高亮
      table.insert(highlights_to_apply, {
        line = row_idx - 1,
        col_start = pos.shortcuts_left,
        col_end = pos.shortcuts_left + 2,
        hl_group = config.highlights.key,
      })

      -- 描述高亮
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
  local opts = { noremap = true, silent = true, buffer = buf }

  for _, shortcut in ipairs(config.shortcuts) do
    vim.keymap.set('n', shortcut.key, shortcut.action, opts)
  end

  vim.keymap.set('n', '<Esc>', ':q<CR>', opts)
  vim.keymap.set('n', 'q', ':q<CR>', opts)
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
  vim.o.showtabline = 0

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
end

vim.api.nvim_create_autocmd('VimEnter', {
  group = group,
  callback = function()
    if vim.fn.argc() == 0 and vim.fn.line2byte('$') == -1 then
      M.show()
    end
    vim.o.laststatus = 2
  end,
})

vim.api.nvim_create_user_command('Dashboard', function()
  M.show()
end, {})

return M
