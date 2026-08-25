local group = vim.api.nvim_create_augroup('Dashboard', { clear = true })
local cmd = require('core.keymap').cmd

local function get_dashboard_images()
  local images = {}
  -- 存放图片的目录，建议将图片放在这个路径下
  local img_dir = vim.fn.stdpath('config') .. '/lua/internal/util/images'
  local exts = { '*.png', '*.jpg', '*.jpeg', '*.webp', '*.gif' }

  for _, ext in ipairs(exts) do
    local files = vim.fn.globpath(img_dir, ext, false, true)
    for _, file in ipairs(files) do
      table.insert(images, file)
    end
  end
  return images
end

local image_files = get_dashboard_images()

local M = {}

local config = {
  image = {
    width = 36,
    height = 18,
    layout_line = 3,
  },

  shortcuts = {
    { key = 'f', desc = 'Open File', action = cmd('FzfLua files') },
    { key = 'e', desc = 'New File', action = cmd('enew') },
    { key = 'o', desc = 'Recent Files', action = cmd('FzfLua oldfiles') },
    {
      key = 'n',
      desc = 'Nvim Config',
      action = cmd('FzfLua files cwd=~/.config/nvim fd_opts=--type\\ f'),
    },
    { key = 'm', desc = 'My Agenda', action = cmd('Agenda') },
    { key = 'b', desc = 'Book Marks', action = cmd('lua require("internal.bookmark").show()') },
    { key = 'u', desc = 'Pack Status', action = cmd('PackStatus') },
    { key = 'q', desc = 'Quit', action = cmd('qa') },
  },

  highlights = {
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

-- 状态管理
local selected_image_path = nil
local current_img_instance = nil

local function center_left(text)
  local width = vim.fn.strdisplaywidth(text)
  return math.max(1, math.floor((vim.o.columns - width) / 2))
end

local function calculate_positions()
  local screen_width = vim.o.columns
  local spacing = string.rep(' ', config.layout.key_desc_spacing)

  -- 图片宽度计算居中
  local lambda_max_width = config.image.width
  local lambda_left = math.max(1, math.floor((screen_width - lambda_max_width) / 2))

  local shortcuts_max_width = 0
  for _, s in ipairs(config.shortcuts) do
    local text = string.format('[%s]%s%s', s.key, spacing, s.desc)
    shortcuts_max_width = math.max(shortcuts_max_width, vim.fn.strdisplaywidth(text))
  end
  local shortcuts_left = math.max(1, math.floor((screen_width - shortcuts_max_width) / 2))

  local top = config.layout.top_offset
  local lambda_lines = config.image.layout_lines or config.image.height
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
  local hour = string.format('%02d', datetime.hour)
  local min = string.format('%02d', datetime.min)
  return string.format(
    '%s %d %s %d %s:%s',
    weekday,
    datetime.year,
    months[datetime.month],
    datetime.day,
    hour,
    min
  )
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
  if current_img_instance then
    current_img_instance:clear()
    current_img_instance = nil
  end

  local lines = {}
  local highlights_to_apply = {}
  local pos = calculate_positions()
  local spacing = string.rep(' ', config.layout.key_desc_spacing)

  for i = 1, pos.total_lines do
    if i == config.layout.top_offset + 1 then
      table.insert(lines, string.rep(' ', pos.lambda_left + 10))
    else
      table.insert(lines, '')
    end
  end

  local greeting_str = '就算是开玩笑也请不要这么说'
  local greeting_left = center_left(greeting_str)
  if pos.greeting_line <= #lines then
    lines[pos.greeting_line] = string.rep(' ', greeting_left - 1) .. greeting_str
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
    lines[pos.date_line] = string.rep(' ', date_left - 1) .. datetime_str
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
    lines[pos.plugin_line] = string.rep(' ', plugin_left - 1) .. plugin_info_str
    table.insert(highlights_to_apply, {
      line = pos.plugin_line - 1,
      col_start = plugin_left - 1,
      col_end = plugin_left - 1 + #plugin_info_str,
      hl_group = config.highlights.footer,
    })
  end

  local cursor = {}
  for i, shortcut in ipairs(config.shortcuts) do
    local row_idx = pos.shortcuts_start + i - 1
    if row_idx <= #lines then
      local shortcut_text = string.format('[%s]%s%s', shortcut.key, spacing, shortcut.desc)
      lines[row_idx] = string.rep(' ', pos.shortcuts_left - 1) .. shortcut_text

      if i == 1 then
        cursor = { row_idx, pos.shortcuts_left + 1 }
      end
      table.insert(highlights_to_apply, {
        line = row_idx - 1,
        col_start = pos.shortcuts_left,
        col_end = pos.shortcuts_left + 2,
        hl_group = config.highlights.key,
      })
      table.insert(highlights_to_apply, {
        line = row_idx - 1,
        col_start = pos.shortcuts_left + 2 + config.layout.key_desc_spacing,
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
  local has_image, image_api = pcall(require, 'image')
  if has_image and selected_image_path then
    vim.defer_fn(function()
      local win = vim.fn.bufwinid(buf)
      if win ~= -1 then
        current_img_instance = image_api.from_file(selected_image_path, {
          window = win,
          buffer = buf,
          x = pos.lambda_left - 1,
          y = config.layout.top_offset,
          width = config.image.width,
          height = config.image.height,

          with_virtual_padding = false,
        })
        if current_img_instance then
          current_img_instance:render()
        end
      end
    end, 10)
  end
end

local function setup_keymaps(buf)
  local opts = { noremap = true, silent = true, buffer = buf }
  for _, shortcut in ipairs(config.shortcuts) do
    vim.keymap.set('n', shortcut.key, function()
      -- 防止在执行fzflua的相关操作的时候图片仍在显示
      if current_img_instance then
        current_img_instance:clear()
        current_img_instance = nil
      end

      local action = shortcut.action
      if type(action) == 'string' then
        local inner_cmd = action:match('^<[cC][mM][dD]>(.*)<[cC][rR]>$')
        if inner_cmd then
          vim.cmd(inner_cmd)
        else
          local keys = vim.api.nvim_replace_termcodes(action, true, false, true)
          vim.api.nvim_feedkeys(keys, 't', false)
        end
      elseif type(action) == 'function' then
        action()
      end
    end, opts)
  end
  local quit_fn = function()
    if current_img_instance then
      current_img_instance:clear()
      current_img_instance = nil
    end
    vim.cmd('qa')
  end
  vim.keymap.set('n', '<Esc>', quit_fn, opts)
  vim.keymap.set('n', 'q', quit_fn, opts)

  vim.keymap.set('n', 't', function()
    render_dashboard(buf)
  end, vim.tbl_extend('force', opts, { desc = 'Refresh dashboard' }))
end

local function opt_handler()
  local save_opts = {
    number = vim.wo.number,
    relativenumber = vim.wo.relativenumber,
    cursorline = vim.wo.cursorline,
    cursorcolumn = vim.wo.cursorcolumn,
    colorcolumn = vim.wo.colorcolumn,
    signcolumn = vim.wo.signcolumn,
    wrap = vim.wo.wrap,
    laststatus = vim.o.laststatus,
    showtabline = vim.o.showtabline,
    listchars = vim.o.listchars,
  }
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

  -- 随机获取图片
  if #image_files > 0 then
    selected_image_path = image_files[math.random(#image_files)]
  else
    selected_image_path = nil
    vim.notify('Dashboard: No images found in lua/internal/util/images/', vim.log.levels.WARN)
  end

  local buf = create_dashboard_buffer()
  vim.api.nvim_set_current_buf(buf)
  render_dashboard(buf)
  setup_highlights()
  setup_keymaps(buf)

  local restore_opt = opt_handler()
  vim.wo.number, vim.wo.relativenumber, vim.wo.cursorline, vim.wo.cursorcolumn, vim.wo.wrap =
    false, false, false, false, false
  vim.wo.colorcolumn, vim.wo.signcolumn, vim.o.laststatus, vim.o.showtabline = '0', 'no', 0, 1
  vim.wo.listchars = 'precedes: '

  vim.api.nvim_create_autocmd('VimResized', {
    buffer = buf,
    group = group,
    callback = function()
      if vim.bo[buf].filetype == 'dashboard' then
        render_dashboard(buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufLeave', 'BufWipeout' }, {
    buffer = buf,
    group = group,
    callback = function()
      if current_img_instance then
        current_img_instance:clear()
        current_img_instance = nil
      end
      restore_opt()
    end,
  })

  vim.api.nvim_create_autocmd('BufEnter', {
    buffer = buf,
    group = group,
    callback = function()
      if vim.bo[buf].filetype == 'dashboard' then
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
        render_dashboard(buf)
      end
    end,
  })

  vim.schedule(function()
    vim.api.nvim_exec_autocmds('User', { pattern = 'DashboardLoaded', modeline = false })
  end)
end

vim.api.nvim_create_user_command('Dashboard', function()
  M.show()
end, {})

return M
