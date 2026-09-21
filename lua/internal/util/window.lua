local api = vim.api
local win = {}

---@param winid? integer
---@return integer
local function normalize_win(winid)
  if winid == nil or winid == 0 then
    return api.nvim_get_current_win()
  end

  return winid
end

---@param opts table
---@return string anchor
local function make_floating_popup_anchor(opts)
  local vertical = opts.height >= 0 and 'N' or 'S'
  local horizontal = opts.width >= 0 and 'W' or 'E'

  return vertical .. horizontal
end

---@param opts table
---@param ui table {height: integer, width: integer}
---@return integer width
---@return integer height
local function make_floating_popup_size(opts, ui)
  local width = math.abs(opts.width)
  local height = math.abs(opts.height)

  if width < 1 then
    width = math.floor(ui.width * width + 0.5)
  end

  if height < 1 then
    height = math.floor(ui.height * height + 0.5)
  end

  width = math.max(1, math.min(width, ui.width))
  height = math.max(1, math.min(height, ui.height))

  return width, height
end

---@param opts table {row: string|number, col: string|number, width: integer, height: integer}
---@param ui table {height: integer, width: integer}
---@param anchor string
---@return number row
---@return number col
local function get_position(opts, ui, anchor)
  local row
  local col

  local vertical_anchor = anchor:sub(1, 1)
  local horizontal_anchor = anchor:sub(2, 2)

  -----------------------------------------------------------------------------
  -- row
  -----------------------------------------------------------------------------

  if type(opts.row) == 'number' then
    row = opts.row
  elseif opts.row == 'c' then
    if vertical_anchor == 'S' then
      row = (ui.height + opts.height) / 2
    else
      row = (ui.height - opts.height) / 2
    end
  elseif opts.row == 't' then
    row = vertical_anchor == 'S' and opts.height or 0
  elseif opts.row == 'b' then
    row = vertical_anchor == 'S' and ui.height or (ui.height - opts.height)
  else
    row = 0
  end

  -----------------------------------------------------------------------------
  -- col
  -----------------------------------------------------------------------------

  if type(opts.col) == 'number' then
    col = opts.col
  elseif opts.col == 'c' then
    if horizontal_anchor == 'E' then
      col = (ui.width + opts.width) / 2
    else
      col = (ui.width - opts.width) / 2
    end
  elseif opts.col == 'l' then
    col = horizontal_anchor == 'E' and opts.width or 0
  elseif opts.col == 'r' then
    col = horizontal_anchor == 'E' and ui.width or (ui.width - opts.width)
  else
    col = 0
  end

  return row, col
end

---@param opts table
---@return table
local function make_floating_popup_options(opts)
  local ui = api.nvim_list_uis()[1] or {
    width = vim.o.columns,
    height = vim.o.lines,
  }

  local conf = vim.deepcopy(opts)

  assert(type(conf.width) == 'number', 'window.new_float: width must be a number')
  assert(type(conf.height) == 'number', 'window.new_float: height must be a number')

  local anchor = conf.anchor or make_floating_popup_anchor(conf)

  conf.width, conf.height = make_floating_popup_size(conf, ui)

  local row, col = get_position(conf, ui, anchor)

  local focusable = conf.focusable
  if focusable == nil then
    focusable = true
  end

  local noautocmd = conf.noautocmd
  if noautocmd == nil then
    noautocmd = false
  end

  local result = {
    anchor = anchor,
    row = row,
    col = col,
    focusable = focusable,
    relative = conf.relative or 'editor',
    style = conf.style or 'minimal',
    width = conf.width,
    height = conf.height,
    border = conf.border or 'rounded',
    title = conf.title or '',
    title_pos = conf.title_pos or 'center',
    zindex = conf.zindex or 50,
    noautocmd = noautocmd,
  }

  if result.relative == 'win' then
    result.win = conf.win
    result.bufpos = conf.bufpos
  end

  return result
end

---@return table
local function default()
  return {
    style = 'minimal',
    border = 'rounded',
    noautocmd = false,
  }
end

-- window queries

---Return current window id.
---@return integer
function win.current()
  return api.nvim_get_current_win()
end

---Check whether a window is valid.
---@param winid? integer
---@return boolean
function win.is_valid(winid)
  winid = normalize_win(winid)

  return api.nvim_win_is_valid(winid)
end

---Get the buffer displayed by a window.
---@param winid? integer
---@return integer?
function win.get_buf(winid)
  winid = normalize_win(winid)

  if not api.nvim_win_is_valid(winid) then
    return nil
  end

  local ok, bufnr = pcall(api.nvim_win_get_buf, winid)

  if not ok then
    return nil
  end

  return bufnr
end

---Get cursor position.
---Returns 0-based row and 0-based byte column.
---@param winid? integer
---@return integer? row
---@return integer? col
function win.cursor(winid)
  winid = normalize_win(winid)

  if not api.nvim_win_is_valid(winid) then
    return nil, nil
  end

  local ok, pos = pcall(api.nvim_win_get_cursor, winid)

  if not ok or not pos then
    return nil, nil
  end

  return pos[1] - 1, pos[2]
end

---Set cursor position.
---Accepts 0-based row and 0-based byte column.
---@param winid? integer
---@param row integer
---@param col integer
---@return boolean
function win.set_cursor(winid, row, col)
  winid = normalize_win(winid)

  if not api.nvim_win_is_valid(winid) then
    return false
  end

  if row == nil or row < 0 or col == nil or col < 0 then
    return false
  end

  return pcall(
    api.nvim_win_set_cursor,
    winid,
    { row + 1, col }
  )
end

---Get window size.
---@param winid? integer
---@return integer? width
---@return integer? height
function win.size(winid)
  winid = normalize_win(winid)

  if not api.nvim_win_is_valid(winid) then
    return nil, nil
  end

  local ok_width, width = pcall(api.nvim_win_get_width, winid)
  local ok_height, height = pcall(api.nvim_win_get_height, winid)

  if not ok_width or not ok_height then
    return nil, nil
  end

  return width, height
end

---Get visible line range of a window.
---Returns a 0-based half-open range: [start_row, end_row).
---@param winid? integer
---@return integer? start_row
---@return integer? end_row
function win.visible_range(winid)
  winid = normalize_win(winid)

  if not api.nvim_win_is_valid(winid) then
    return nil, nil
  end

  local ok, start_row, end_row = pcall(function()
    return api.nvim_win_call(winid, function()
      return vim.fn.line('w0') - 1, vim.fn.line('w$')
    end)
  end)

  if not ok then
    return nil, nil
  end

  return start_row, end_row
end

---Return all windows currently displaying a buffer.
---@param buf? integer
---@return integer[]
function win.for_buffer(buf)
  if buf == nil or buf == 0 then
    buf = api.nvim_get_current_buf()
  end

  if not api.nvim_buf_is_valid(buf) then
    return {}
  end

  local result = {}

  for _, winid in ipairs(api.nvim_list_wins()) do
    if
      api.nvim_win_is_valid(winid)
      and api.nvim_win_get_buf(winid) == buf
    then
      result[#result + 1] = winid
    end
  end

  return result
end

---Check whether a window is floating.
---@param winid? integer
---@return boolean
function win.is_floating(winid)
  winid = normalize_win(winid)

  if not api.nvim_win_is_valid(winid) then
    return false
  end

  local ok, conf = pcall(api.nvim_win_get_config, winid)

  if not ok or not conf then
    return false
  end

  return conf.relative ~= nil and conf.relative ~= ''
end

-- float object

local obj = {}
obj.__index = obj

---Set buffer-local option(s).
---@param name string|table
---@param value? any
---@return table self
function obj:bufopt(name, value)
  if not self.bufnr or not api.nvim_buf_is_valid(self.bufnr) then
    return self
  end

  if type(name) == 'table' then
    for key, val in pairs(name) do
      api.nvim_set_option_value(
        key,
        val,
        { buf = self.bufnr }
      )
    end
  else
    api.nvim_set_option_value(
      name,
      value,
      { buf = self.bufnr }
    )
  end

  return self
end

---Set window-local option(s).
---@param name string|table
---@param value? any
---@return table self
function obj:winopt(name, value)
  if not self.winid or not api.nvim_win_is_valid(self.winid) then
    return self
  end

  if type(name) == 'table' then
    for key, val in pairs(name) do
      api.nvim_set_option_value(
        key,
        val,
        { win = self.winid }
      )
    end
  else
    api.nvim_set_option_value(
      name,
      value,
      { win = self.winid }
    )
  end

  return self
end

---Get buffer id and window id.
---@return integer bufnr
---@return integer winid
function obj:wininfo()
  return self.bufnr, self.winid
end

---Check whether this floating-window object is still valid.
---@return boolean
function obj:is_valid()
  return self.winid ~= nil
    and api.nvim_win_is_valid(self.winid)
    and self.bufnr ~= nil
    and api.nvim_buf_is_valid(self.bufnr)
end

---Close this floating window.
---@param force? boolean
---@return boolean
function obj:close(force)
  if not self.winid or not api.nvim_win_is_valid(self.winid) then
    return false
  end

  local ok = pcall(
    api.nvim_win_close,
    self.winid,
    force == true
  )

  if ok then
    self.winid = nil
  end

  return ok
end

---Create a floating window.
---
---Existing calling style remains supported:
---
---  win:new_float(opts, true, true)
---    :bufopt('bufhidden', 'hide')
---    :wininfo()
---
---@param float_opt table
---@param enter? boolean
---@param force? boolean
---@return table
function win:new_float(float_opt, enter, force)
  assert(type(float_opt) == 'table', 'window.new_float: float_opt must be a table')

  enter = enter == true
  local opts = vim.deepcopy(float_opt)
  local bufnr = opts.bufnr
  opts.bufnr = nil

  if not bufnr or not api.nvim_buf_is_valid(bufnr) then
    bufnr = api.nvim_create_buf(false, false)
  end

  -- force=true enables the shorthand positioning used by the existing config:
  --
  --   row = 't' | 'c' | 'b'
  --   col = 'l' | 'c' | 'r'
  --   width/height may be fractions of the UI.

  local config

  if force then
    config = make_floating_popup_options(opts)
  else
    config = vim.tbl_extend(
      'force',
      default(),
      opts
    )
  end

  local winid = api.nvim_open_win(
    bufnr,
    enter,
    config
  )

  return setmetatable({
    bufnr = bufnr,
    winid = winid,
  }, obj)
end

return win
