local api = vim.api
local group = api.nvim_create_augroup('Dashboard', { clear = true })
local cmd = require('core.keymap').cmd
local window = require('internal.util.window')

local M = {}

local ns = api.nvim_create_namespace('dashboard')

local config = {
  image = {
    width = 36,
    height = 18,
    layout_lines = 18,
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
    {
      key = 'm',
      desc = 'My Agenda',
      action = cmd('Agenda'),
    },
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

local image_quotes = {
  ['Tomoyo.png'] = '❤️ 就算是开玩笑也请不要这么说 ❤️',
  ['Tomoyo2.png'] = '如果离开了我的话，每天早上谁去叫你起床',
  ['Tomoyo3.png'] = '能和我这样的女孩子交往，谢谢你',
  ['__default__'] = 'Hello,Chamomile',
}

local state = {
  buf = nil,
  win = nil,
  image_path = nil,
  image_instance = nil,
  quote = '',
  render_generation = 0,
}

local function get_dashboard_images()
  local images = {}
  local img_dir = vim.fn.stdpath('config') .. '/lua/internal/util/images'
  local exts = { '*.png', '*.jpg', '*.jpeg', '*.webp', '*.gif' }

  for _, ext in ipairs(exts) do
    local files = vim.fn.globpath(img_dir, ext, false, true)
    for _, file in ipairs(files) do
      images[#images + 1] = file
    end
  end

  table.sort(images)
  return images
end

local function select_random_image()
  local images = get_dashboard_images()

  if #images == 0 then
    state.image_path = nil
    state.quote = image_quotes.__default__
    vim.notify('Dashboard: No images found in lua/internal/util/images/', vim.log.levels.WARN)
    return
  end

  local seed = tonumber((vim.uv or vim.loop).hrtime()) or 0
  local index = (seed % #images) + 1

  state.image_path = images[index]

  local filename = vim.fn.fnamemodify(state.image_path, ':t')
  state.quote = image_quotes[filename] or image_quotes.__default__
end

local function resolve_window(buf, preferred)
  if
    preferred
    and window.is_valid(preferred)
    and window.get_buf(preferred) == buf
  then
    return preferred
  end

  local wins = window.for_buffer(buf)
  return wins[1]
end

local function is_dashboard_active(buf, winid)
  if not winid or not window.is_valid(winid) then
    return false
  end

  return api.nvim_get_current_win() == winid
    and window.get_buf(winid) == buf
end

local function center_col(text, winid)
  local win_width = select(1, window.size(winid)) or vim.o.columns
  local text_width = vim.fn.strdisplaywidth(text)

  -- 所有列坐标统一为 0-based。
  return math.max(0, math.floor((win_width - text_width) / 2))
end

local function calculate_positions(winid)
  local win_width = select(1, window.size(winid)) or vim.o.columns
  local spacing = string.rep(' ', config.layout.key_desc_spacing)

  local image_width = math.max(1, math.min(config.image.width, win_width))
  local image_left = math.max(0, math.floor((win_width - image_width) / 2))

  local shortcuts_max_width = 0
  for _, shortcut in ipairs(config.shortcuts) do
    local text = string.format('[%s]%s%s', shortcut.key, spacing, shortcut.desc)
    shortcuts_max_width = math.max(shortcuts_max_width, vim.fn.strdisplaywidth(text))
  end

  local shortcuts_left = math.max(0, math.floor((win_width - shortcuts_max_width) / 2))


  local top = config.layout.top_offset
  local image_lines = config.image.layout_lines or config.image.height
  local date_line = top + image_lines + config.layout.art_date_gap
  local plugin_line = date_line + config.layout.date_plugin_gap
  local shortcuts_start = plugin_line + config.layout.plugin_shortcuts_gap
  local shortcuts_end = shortcuts_start + #config.shortcuts - 1
  local greeting_line = shortcuts_end + config.layout.shortcuts_greeting_gap

  return {
    image_left = image_left,
    image_width = image_width,
    shortcuts_left = shortcuts_left,
    date_line = date_line,
    plugin_line = plugin_line,
    shortcuts_start = shortcuts_start,
    greeting_line = greeting_line,
    total_lines = math.max(1, greeting_line),
  }
end

local function setup_highlights()
  local highlights = {
    DashboardKey = { link = 'Constant' },
    DashboardDesc = { link = 'Function' },
    DashboardDate = { link = 'PreProc' },
    DashboardFooter = { link = 'Keyword' },
    DashboardGreeting = { link = 'String' },
  }

  for name, opts in pairs(highlights) do
    api.nvim_set_hl(0, name, opts)
  end
end

local function get_datetime()
  local datetime = os.date('*t')
  local weekdays = { 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' }
  local months = { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' }

  return string.format(
    '%s %d %s %d %02d:%02d',
    weekdays[datetime.wday],
    datetime.year,
    months[datetime.month],
    datetime.day,
    datetime.hour,
    datetime.min
  )
end

local function path_key(path)
  if not path or path == '' then
    return nil
  end

  local normalized = vim.fs.normalize(path)
  local uname = (vim.uv or vim.loop).os_uname()

  if uname and uname.sysname == 'Windows_NT' then
    normalized = normalized:lower()
  end

  return normalized
end

local function get_plugin_info()
  if not vim.pack or not vim.pack.get then
    return 'Neovim loaded 0/0 plugins in ' .. tostring(vim.g.nvim_startup_time or '0') .. 'ms'
  end

  local ok, plugins = pcall(vim.pack.get, nil, { info = false })
  if not ok or type(plugins) ~= 'table' then
    plugins = {}
  end

  local rtp_set = {}
  for _, path in ipairs(vim.opt.rtp:get()) do
    local key = path_key(path)
    if key then
      rtp_set[key] = true
    end
  end

  local loaded = 0
  for _, plugin in ipairs(plugins) do
    local key = path_key(plugin.path)
    if key and rtp_set[key] then
      loaded = loaded + 1
    end
  end

  return string.format(
    'Neovim loaded %d/%d plugins in %sms',
    loaded,
    #plugins,
    tostring(vim.g.nvim_startup_time or '0')
  )
end

local function is_empty_startup_buffer()
  if vim.fn.argc() > 0 then
    return false
  end

  local buf = api.nvim_get_current_buf()

  if not api.nvim_buf_is_valid(buf) or not api.nvim_buf_is_loaded(buf) then
    return false
  end

  if vim.bo[buf].buftype ~= '' or vim.bo[buf].modified then
    return false
  end

  if api.nvim_buf_get_name(buf) ~= '' then
    return false
  end

  if api.nvim_buf_line_count(buf) ~= 1 then
    return false
  end

  local line = api.nvim_buf_get_lines(buf, 0, 1, false)[1]
  return line == ''
end

local function create_dashboard_buffer(reuse_current)
  local winid = api.nvim_get_current_win()
  local buf

  if reuse_current then
    buf = api.nvim_get_current_buf()
  else
    buf = api.nvim_create_buf(false, true)

    local ok, err = pcall(api.nvim_win_set_buf, winid, buf)
    if not ok then
      pcall(api.nvim_buf_delete, buf, { force = true })
      vim.notify('Dashboard: failed to open dashboard buffer: ' .. tostring(err), vim.log.levels.ERROR)
      return nil, nil
    end
  end

  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false
  vim.bo[buf].undolevels = -1
  vim.bo[buf].modifiable = false

  return buf, winid
end

-------------------------------------------------------------------------------
-- image lifecycle
-------------------------------------------------------------------------------

local function clear_image()
  local image = state.image_instance
  state.image_instance = nil

  if image then
    pcall(function()
      image:clear()
    end)
  end
end

local function invalidate_image_render()
  state.render_generation = state.render_generation + 1
  clear_image()
end

local function render_image(buf, winid, pos, generation)
  if not state.image_path then
    return
  end

  vim.defer_fn(function()
    if generation ~= state.render_generation then
      return
    end

    if not api.nvim_buf_is_valid(buf) then
      return
    end

    winid = resolve_window(buf, winid)
    if not winid then
      return
    end

    -- 图片只在 Dashboard 自己是当前活动窗口时显示。
    -- Yazi / Lazygit / FzfLua 等浮窗取得焦点后，Dashboard 虽然仍然
    -- 可见，但不应该继续保留 kitty 图片。
    if not is_dashboard_active(buf, winid) then
      return
    end

    -- require 放到 defer 内部：如果 image.nvim 是由 DashboardLoaded
    -- 懒加载的，它有机会先完成加载，同时不改变 DashboardLoaded 的原有时序。
    local ok_image, image_api = pcall(require, 'image')
    if not ok_image or not image_api then
      return
    end

    local ok_instance, instance = pcall(image_api.from_file, state.image_path, {
      window = winid,
      buffer = buf,
      x = pos.image_left,
      y = config.layout.top_offset,
      width = pos.image_width,
      height = config.image.height,
      with_virtual_padding = false,
    })

    if not ok_instance or not instance then
      return
    end

    if generation ~= state.render_generation then
      pcall(function()
        instance:clear()
      end)
      return
    end

    state.image_instance = instance

    local ok_render = pcall(function()
      instance:render()
    end)

    if not ok_render and state.image_instance == instance then
      state.image_instance = nil
      pcall(function()
        instance:clear()
      end)
    end
  end, 10)
end

-------------------------------------------------------------------------------
-- rendering
-------------------------------------------------------------------------------

local function render_dashboard(buf, preferred_win)
  if not api.nvim_buf_is_valid(buf) or not api.nvim_buf_is_loaded(buf) then
    return
  end

  local winid = resolve_window(buf, preferred_win)
  if not winid then
    return
  end

  state.render_generation = state.render_generation + 1
  local generation = state.render_generation

  clear_image()

  local lines = {}
  local highlights = {}
  local pos = calculate_positions(winid)
  local spacing = string.rep(' ', config.layout.key_desc_spacing)

  for i = 1, pos.total_lines do
    if i == config.layout.top_offset + 1 then
      -- image.nvim 在关闭 virtual padding 时，给图片所在行留出足够宽度。
      lines[i] = string.rep(' ', pos.image_left + pos.image_width)
    else
      lines[i] = ''
    end
  end

  local greeting = state.quote
  local greeting_left = center_col(greeting, winid)

  if pos.greeting_line <= #lines then
    lines[pos.greeting_line] = string.rep(' ', greeting_left) .. greeting
    highlights[#highlights + 1] = {
      line = pos.greeting_line - 1,
      col_start = greeting_left,
      col_end = greeting_left + #greeting,
      hl_group = config.highlights.greeting,
    }
  end

  local datetime = get_datetime()
  local date_left = center_col(datetime, winid)

  if pos.date_line <= #lines then
    lines[pos.date_line] = string.rep(' ', date_left) .. datetime
    highlights[#highlights + 1] = {
      line = pos.date_line - 1,
      col_start = date_left,
      col_end = date_left + #datetime,
      hl_group = config.highlights.date,
    }
  end

  local plugin_info = get_plugin_info()
  local plugin_left = center_col(plugin_info, winid)

  if pos.plugin_line <= #lines then
    lines[pos.plugin_line] = string.rep(' ', plugin_left) .. plugin_info
    highlights[#highlights + 1] = {
      line = pos.plugin_line - 1,
      col_start = plugin_left,
      col_end = plugin_left + #plugin_info,
      hl_group = config.highlights.footer,
    }
  end

  local cursor_row
  local cursor_col

  for i, shortcut in ipairs(config.shortcuts) do
    local row = pos.shortcuts_start + i - 1

    if row <= #lines then
      local key_text = '[' .. shortcut.key .. ']'
      local shortcut_text = key_text .. spacing .. shortcut.desc
      local left = pos.shortcuts_left

      lines[row] = string.rep(' ', left) .. shortcut_text

      -- highlight / cursor 都使用 byte column，并统一为 0-based。
      local key_start = left + 1
      local key_end = key_start + #shortcut.key
      local desc_start = left + #key_text + config.layout.key_desc_spacing
      local desc_end = left + #shortcut_text

      if i == 1 then
        cursor_row = row - 1
        cursor_col = key_start
      end

      highlights[#highlights + 1] = {
        line = row - 1,
        col_start = key_start,
        col_end = key_end,
        hl_group = config.highlights.key,
      }

      highlights[#highlights + 1] = {
        line = row - 1,
        col_start = desc_start,
        col_end = desc_end,
        hl_group = config.highlights.desc,
      }
    end
  end

  api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  vim.bo[buf].modifiable = true
  local ok_lines, err = pcall(api.nvim_buf_set_lines, buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  if not ok_lines then
    vim.notify('Dashboard: failed to render buffer: ' .. tostring(err), vim.log.levels.ERROR)
    return
  end

  if vim.bo[buf].filetype ~= 'dashboard' then
    vim.bo[buf].filetype = 'dashboard'
  end

  for _, hl in ipairs(highlights) do
    pcall(
      api.nvim_buf_add_highlight,
      buf,
      ns,
      hl.hl_group,
      hl.line,
      hl.col_start,
      hl.col_end
    )
  end

  if cursor_row and cursor_col then
    window.set_cursor(winid, cursor_row, cursor_col)
  end

  render_image(buf, winid, pos, generation)
end

-------------------------------------------------------------------------------
-- options / lifecycle
-------------------------------------------------------------------------------

local function option_handler(winid)
  local saved_window = {
    number = vim.wo[winid].number,
    relativenumber = vim.wo[winid].relativenumber,
    cursorline = vim.wo[winid].cursorline,
    cursorcolumn = vim.wo[winid].cursorcolumn,
    colorcolumn = vim.wo[winid].colorcolumn,
    signcolumn = vim.wo[winid].signcolumn,
    wrap = vim.wo[winid].wrap,
    listchars = vim.wo[winid].listchars,
  }

  local saved_global = {
    laststatus = vim.o.laststatus,
    showtabline = vim.o.showtabline,
  }

  local window_restored = false
  local global_active = false

  local function apply_window()
    if not window.is_valid(winid) then
      return
    end

    vim.wo[winid].number = false
    vim.wo[winid].relativenumber = false
    vim.wo[winid].cursorline = false
    vim.wo[winid].cursorcolumn = false
    vim.wo[winid].colorcolumn = ''
    vim.wo[winid].signcolumn = 'no'
    vim.wo[winid].wrap = false
    vim.wo[winid].listchars = 'precedes: '
  end

  local function restore_window()
    if window_restored then
      return
    end

    window_restored = true

    if not window.is_valid(winid) then
      return
    end

    vim.wo[winid].number = saved_window.number
    vim.wo[winid].relativenumber = saved_window.relativenumber
    vim.wo[winid].cursorline = saved_window.cursorline
    vim.wo[winid].cursorcolumn = saved_window.cursorcolumn
    vim.wo[winid].colorcolumn = saved_window.colorcolumn
    vim.wo[winid].signcolumn = saved_window.signcolumn
    vim.wo[winid].wrap = saved_window.wrap
    vim.wo[winid].listchars = saved_window.listchars
  end

  local function apply_global()
    if global_active then
      return
    end

    global_active = true
    vim.o.laststatus = 0
    vim.o.showtabline = 1
  end

  local function restore_global()
    if not global_active then
      return
    end

    global_active = false
    vim.o.laststatus = saved_global.laststatus
    vim.o.showtabline = saved_global.showtabline
  end

  local function apply()
    apply_window()
    apply_global()
  end

  local function restore()
    restore_global()
    restore_window()
  end

  return {
    apply = apply,
    apply_global = apply_global,
    restore_global = restore_global,
    restore = restore,
  }
end

local function setup_keymaps(buf)
  local opts = {
    noremap = true,
    silent = true,
    buffer = buf,
  }

  for _, shortcut in ipairs(config.shortcuts) do
    vim.keymap.set('n', shortcut.key, function()
      if type(shortcut.pre_action) == 'function' and shortcut.pre_action() == false then
        return
      end

      -- 清掉当前图片，并取消还没有执行的旧图片渲染任务。
      invalidate_image_render()

      local action = shortcut.action

      if type(action) == 'string' then
        local inner_cmd = action:match('^<[cC][mM][dD]>(.*)<[cC][rR]>$')

        if inner_cmd then
          vim.cmd(inner_cmd)
        else
          local keys = api.nvim_replace_termcodes(action, true, false, true)
          api.nvim_feedkeys(keys, 't', false)
        end
      elseif type(action) == 'function' then
        action()
      end

      -- 对快速打开/关闭的 picker 保留原来的恢复行为。
      vim.defer_fn(function()
        if
          api.nvim_buf_is_valid(buf)
          and is_dashboard_active(buf, state.win)
          and not state.image_instance
        then
          render_dashboard(buf, state.win)
        end
      end, 50)
    end, opts)
  end

  vim.keymap.set('n', '<Esc>', function()
    invalidate_image_render()
    vim.cmd('qa')
  end, vim.tbl_extend('force', opts, { desc = 'Quit' }))

  vim.keymap.set('n', 't', function()
    render_dashboard(buf, api.nvim_get_current_win())
  end, vim.tbl_extend('force', opts, { desc = 'Refresh dashboard' }))
end

local function setup_lifecycle(buf, winid, options)
  local cleaned = false
  local resize_autocmd
  local winleave_autocmd
  local enter_autocmd

  local function cleanup()
    if cleaned then
      return
    end

    cleaned = true
    invalidate_image_render()
    options.restore()

    if resize_autocmd then
      pcall(api.nvim_del_autocmd, resize_autocmd)
      resize_autocmd = nil
    end

    if winleave_autocmd then
      pcall(api.nvim_del_autocmd, winleave_autocmd)
      winleave_autocmd = nil
    end

    if enter_autocmd then
      pcall(api.nvim_del_autocmd, enter_autocmd)
      enter_autocmd = nil
    end

    if state.buf == buf then
      state.buf = nil
      state.win = nil
      state.image_path = nil
      state.quote = ''
    end
  end

  resize_autocmd = api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, {
    group = group,
    callback = function()
      if
        not cleaned
        and api.nvim_buf_is_valid(buf)
        and window.is_valid(winid)
        and window.get_buf(winid) == buf
      then
        render_dashboard(buf, winid)
      end
    end,
  })

  -- laststatus / showtabline 是全局选项。
  -- 离开 Dashboard window（包括切换 split、tabpage、PackStatus confirmation tab）
  -- 时立即恢复，不能等到 Dashboard buffer 被 wipe。
  winleave_autocmd = api.nvim_create_autocmd('WinLeave', {
    group = group,
    callback = function()
      if cleaned or not window.is_valid(winid) then
        return
      end

      if api.nvim_get_current_win() == winid and window.get_buf(winid) == buf then
        -- Dashboard 只要失去焦点就隐藏图片。
        -- 这覆盖了通过全局映射打开 Yazi / Lazygit / terminal float 等
        -- 不经过 Dashboard shortcut handler 的情况。
        invalidate_image_render()
        options.restore_global()
      end
    end,
  })

  -- FzfLua / 临时浮窗 / 其他 tab 关闭后重新进入 Dashboard 时，
  -- 重新应用 Dashboard 的全局 UI 选项，并在需要时恢复图片。
  local enter_scheduled = false

  local function schedule_dashboard_enter()
    if enter_scheduled or cleaned then
      return
    end

    enter_scheduled = true

    vim.schedule(function()
      enter_scheduled = false

      if cleaned or not api.nvim_buf_is_valid(buf) then
        return
      end

      local current_win = api.nvim_get_current_win()

      if not is_dashboard_active(buf, winid) then
        return
      end

      options.apply_global()

      if not state.image_instance then
        render_dashboard(buf, current_win)
      end
    end)
  end

  enter_autocmd = api.nvim_create_autocmd({ 'WinEnter', 'TabEnter' }, {
    group = group,
    callback = schedule_dashboard_enter,
  })

  -- BufWinLeave / BufWipeout 只负责 Dashboard 自身真正离开窗口后的最终清理。
  api.nvim_create_autocmd({ 'BufWinLeave', 'BufWipeout' }, {
    buffer = buf,
    group = group,
    once = true,
    callback = cleanup,
  })
end

-------------------------------------------------------------------------------
-- public
-------------------------------------------------------------------------------

---@param force? boolean Explicit :Dashboard calls pass true.
function M.show(force)
  local current_buf = api.nvim_get_current_buf()

  -- Dashboard 已经在当前窗口时，把命令当作刷新。
  if vim.bo[current_buf].filetype == 'dashboard' then
    render_dashboard(current_buf, api.nvim_get_current_win())
    return
  end

  -- 如果另一个窗口已经显示 Dashboard，直接跳过去，不创建第二份全局状态。
  if state.buf and api.nvim_buf_is_valid(state.buf) then
    local wins = window.for_buffer(state.buf)
    if wins[1] then
      api.nvim_set_current_win(wins[1])
      render_dashboard(state.buf, wins[1])
      return
    end
  end

  local reuse_current = is_empty_startup_buffer()

  if not force and not reuse_current then
    return
  end

  select_random_image()
  setup_highlights()

  local buf, winid = create_dashboard_buffer(reuse_current)
  if not buf or not winid then
    return
  end

  state.buf = buf
  state.win = winid

  local options = option_handler(winid)
  options.apply()

  setup_keymaps(buf)
  setup_lifecycle(buf, winid, options)
  render_dashboard(buf, winid)

  vim.schedule(function()
    api.nvim_exec_autocmds('User', {
      pattern = 'DashboardLoaded',
      modeline = false,
    })
  end)
end

api.nvim_create_autocmd('ColorScheme', {
  group = group,
  callback = setup_highlights,
})

api.nvim_create_user_command('Dashboard', function()
  -- 显式执行 :Dashboard 时允许从普通文件打开一个独立 scratch buffer。
  M.show(true)
end, {})

return M
