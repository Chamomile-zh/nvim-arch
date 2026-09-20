local M = {}

local api = vim.api

-------------------------------------------------------------------------------
-- FFI
-------------------------------------------------------------------------------

local ffi
local ml_get
local has_ffi = false

do
  local ok, lib = pcall(require, 'ffi')

  if ok and lib then
    ffi = lib

    local ok_cdef = pcall(function()
      ffi.cdef([[
        typedef int32_t linenr_T;
        char *ml_get(linenr_T lnum);
      ]])
    end)

    -- cdef 可能因为其他模块已经声明过相同类型而失败，
    -- 但 ml_get 仍然可能可以直接访问。
    local ok_symbol, symbol = pcall(function()
      return ffi.C.ml_get
    end)

    if ok_symbol and symbol then
      ml_get = symbol
      has_ffi = true
    elseif ok_cdef then
      has_ffi = false
    end
  end
end

-------------------------------------------------------------------------------
-- internal helpers
-------------------------------------------------------------------------------

---@param buf? integer
---@return integer
local function normalize_buf(buf)
  if buf == nil or buf == 0 then
    return api.nvim_get_current_buf()
  end

  return buf
end

---@param row integer
---@return string?
local function get_line_ffi(row)
  if not has_ffi or not ml_get then
    return nil
  end

  -- ml_get() 使用 1-based line number。
  local ok, ptr = pcall(
    ml_get,
    row + 1
  )

  if not ok or ptr == nil then
    return nil
  end

  local ok_string, line = pcall(
    ffi.string,
    ptr
  )

  if not ok_string then
    return nil
  end

  return line
end

-------------------------------------------------------------------------------
-- state
-------------------------------------------------------------------------------

---@param buf? integer
---@return boolean
function M.is_valid(buf)
  buf = normalize_buf(buf)

  return api.nvim_buf_is_valid(buf)
end

---@param buf? integer
---@return boolean
function M.is_loaded(buf)
  buf = normalize_buf(buf)

  return api.nvim_buf_is_valid(buf)
    and api.nvim_buf_is_loaded(buf)
end

---Buffer 是否有效并且已经加载到内存。
---@param buf? integer
---@return boolean
function M.is_available(buf)
  return M.is_loaded(buf)
end

---是否为普通文件/编辑 Buffer。
---
---会排除：
---  terminal
---  quickfix
---  prompt
---  nofile
---  help 等特殊 buffer。
---@param buf? integer
---@return boolean
function M.is_normal(buf)
  buf = normalize_buf(buf)

  if not M.is_available(buf) then
    return false
  end

  return vim.bo[buf].buftype == ''
end

---Buffer 是否可以修改。
---@param buf? integer
---@return boolean
function M.is_editable(buf)
  buf = normalize_buf(buf)

  if not M.is_normal(buf) then
    return false
  end

  return vim.bo[buf].modifiable
    and not vim.bo[buf].readonly
end

-------------------------------------------------------------------------------
-- basic information
-------------------------------------------------------------------------------

---@param buf? integer
---@return integer
function M.line_count(buf)
  buf = normalize_buf(buf)

  if not M.is_available(buf) then
    return 0
  end

  local ok, count = pcall(
    api.nvim_buf_line_count,
    buf
  )

  if not ok then
    return 0
  end

  return count
end

---@param buf? integer
---@return integer
function M.changedtick(buf)
  buf = normalize_buf(buf)

  if not M.is_available(buf) then
    return -1
  end

  local ok, tick = pcall(
    api.nvim_buf_get_changedtick,
    buf
  )

  if not ok then
    return -1
  end

  return tick
end

-------------------------------------------------------------------------------
-- line reading
-------------------------------------------------------------------------------

---读取当前 Buffer 的一行。
---
---这是高频路径：
---优先使用 ml_get()，失败时自动 fallback 到官方 API。
---
---@param row integer 0-based
---@return string
function M.get_current_line(row)
  if row == nil or row < 0 then
    return ''
  end

  local buf = api.nvim_get_current_buf()

  if not M.is_available(buf) then
    return ''
  end

  if row >= M.line_count(buf) then
    return ''
  end

  ---------------------------------------------------------------------------
  -- FFI fast path
  ---------------------------------------------------------------------------

  local line = get_line_ffi(row)

  if line ~= nil then
    return line
  end

  ---------------------------------------------------------------------------
  -- API fallback
  ---------------------------------------------------------------------------

  local ok, lines = pcall(
    api.nvim_buf_get_lines,
    buf,
    row,
    row + 1,
    false
  )

  if not ok or not lines then
    return ''
  end

  return lines[1] or ''
end

---读取任意 Buffer 的一行。
---
---如果读取的是当前 Buffer，会自动使用 FFI fast path。
---
---@param buf? integer
---@param row integer 0-based
---@return string
function M.get_line(buf, row)
  buf = normalize_buf(buf)

  if row == nil or row < 0 then
    return ''
  end

  if not M.is_available(buf) then
    return ''
  end

  if row >= M.line_count(buf) then
    return ''
  end

  ---------------------------------------------------------------------------
  -- ml_get() 只能安全地用于当前 Buffer。
  ---------------------------------------------------------------------------

  if buf == api.nvim_get_current_buf() then
    local line = get_line_ffi(row)

    if line ~= nil then
      return line
    end
  end

  ---------------------------------------------------------------------------
  -- API path
  ---------------------------------------------------------------------------

  local ok, lines = pcall(
    api.nvim_buf_get_lines,
    buf,
    row,
    row + 1,
    false
  )

  if not ok or not lines then
    return ''
  end

  return lines[1] or ''
end

---读取一个行区间。
---
---start_row: 0-based, inclusive
---end_row:   0-based, exclusive
---
---例如：
---
---  get_lines(buf, 10, 20)
---
---返回第 10 ~ 19 行。
---
---@param buf? integer
---@param start_row integer
---@param end_row integer
---@return string[]
function M.get_lines(
  buf,
  start_row,
  end_row
)
  buf = normalize_buf(buf)

  if not M.is_available(buf) then
    return {}
  end

  start_row = start_row or 0
  end_row = end_row or start_row

  if start_row < 0 then
    start_row = 0
  end

  if end_row <= start_row then
    return {}
  end

  local ok, lines = pcall(
    api.nvim_buf_get_lines,
    buf,
    start_row,
    end_row,
    false
  )

  if not ok or not lines then
    return {}
  end

  return lines
end

-------------------------------------------------------------------------------
-- text reading
-------------------------------------------------------------------------------

---读取任意文本区间。
---
---所有 row / col 均为 0-based。
---
---@param buf? integer
---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
---@return string[]
function M.get_text(
  buf,
  start_row,
  start_col,
  end_row,
  end_col
)
  buf = normalize_buf(buf)

  if not M.is_available(buf) then
    return {}
  end

  local ok, text = pcall(
    api.nvim_buf_get_text,
    buf,
    start_row,
    start_col,
    end_row,
    end_col,
    {}
  )

  if not ok or not text then
    return {}
  end

  return text
end

-------------------------------------------------------------------------------
-- writing
-------------------------------------------------------------------------------

---替换完整行。
---
---start_row: inclusive
---end_row:   exclusive
---
---@param buf? integer
---@param start_row integer
---@param end_row integer
---@param lines string[]
---@return boolean
function M.set_lines(
  buf,
  start_row,
  end_row,
  lines
)
  buf = normalize_buf(buf)

  if not M.is_available(buf) then
    return false
  end

  if not vim.bo[buf].modifiable then
    return false
  end

  local ok = pcall(
    api.nvim_buf_set_lines,
    buf,
    start_row,
    end_row,
    false,
    lines
  )

  return ok
end

---替换一个文本区域。
---
---所有 row / col 均为 0-based。
---
---@param buf? integer
---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
---@param replacement string[]
---@return boolean
function M.set_text(
  buf,
  start_row,
  start_col,
  end_row,
  end_col,
  replacement
)
  buf = normalize_buf(buf)

  if not M.is_available(buf) then
    return false
  end

  if not vim.bo[buf].modifiable then
    return false
  end

  local ok = pcall(
    api.nvim_buf_set_text,
    buf,
    start_row,
    start_col,
    end_row,
    end_col,
    replacement
  )

  return ok
end

-------------------------------------------------------------------------------
-- offsets
-------------------------------------------------------------------------------

---获取某一行相对于整个 Buffer 开头的 byte offset。
---
---@param buf? integer
---@param row integer 0-based
---@return integer
function M.byte_offset(buf, row)
  buf = normalize_buf(buf)

  if not M.is_available(buf) then
    return -1
  end

  if row == nil or row < 0 then
    return -1
  end

  local ok, offset = pcall(
    api.nvim_buf_get_offset,
    buf,
    row
  )

  if not ok then
    return -1
  end

  return offset
end

---把 (row, col) 转换成相对于整个 Buffer 的 byte offset。
---
---@param buf? integer
---@param row integer 0-based
---@param col integer 0-based byte column
---@return integer
function M.position_to_offset(
  buf,
  row,
  col
)
  local offset =
    M.byte_offset(buf, row)

  if offset < 0 then
    return -1
  end

  return offset + (col or 0)
end

-------------------------------------------------------------------------------
-- buffer attach
-------------------------------------------------------------------------------

---监听 Buffer 的实际文本变化。
---
---相比 TextChanged / TextChangedI，
---nvim_buf_attach() 可以直接得到具体发生变化的行范围。
---
---支持：
---
---  buffer.attach(buf, {
---    on_change = function(change)
---      print(change.first_row)
---      print(change.old_end_row)
---      print(change.new_end_row)
---    end,
---
---    on_bytes = function(change)
---      ...
---    end,
---
---    on_reload = function(buf)
---      ...
---    end,
---
---    on_detach = function(buf)
---      ...
---    end,
---  })
---
---@param buf? integer
---@param opts table
---@return boolean
function M.attach(buf, opts)
  buf = normalize_buf(buf)
  opts = opts or {}

  if not M.is_available(buf) then
    return false
  end

  local callbacks = {}

  ---------------------------------------------------------------------------
  -- line-level changes
  ---------------------------------------------------------------------------

  if opts.on_change then
    callbacks.on_lines = function(
      _,
      changed_buf,
      changedtick,
      first_row,
      old_end_row,
      new_end_row,
      old_byte_size
    )
      local ok, result = pcall(
        opts.on_change,
        {
          buf = changed_buf,

          changedtick =
            changedtick,

          -- 全部都是 0-based。
          first_row =
            first_row,

          old_end_row =
            old_end_row,

          new_end_row =
            new_end_row,

          old_byte_size =
            old_byte_size,
        }
      )

      if not ok then
        vim.schedule(function()
          vim.notify(
            result,
            vim.log.levels.ERROR,
            {
              title = 'buffer.attach',
            }
          )
        end)
      end

      return false
    end
  end

  ---------------------------------------------------------------------------
  -- byte-level changes
  ---------------------------------------------------------------------------

  if opts.on_bytes then
    callbacks.on_bytes = function(
      _,
      changed_buf,
      changedtick,
      start_row,
      start_col,
      start_byte,
      old_end_row,
      old_end_col,
      old_end_byte,
      new_end_row,
      new_end_col,
      new_end_byte
    )
      local ok, result = pcall(
        opts.on_bytes,
        {
          buf = changed_buf,

          changedtick =
            changedtick,

          start_row =
            start_row,

          start_col =
            start_col,

          start_byte =
            start_byte,

          old_end_row =
            old_end_row,

          old_end_col =
            old_end_col,

          old_end_byte =
            old_end_byte,

          new_end_row =
            new_end_row,

          new_end_col =
            new_end_col,

          new_end_byte =
            new_end_byte,
        }
      )

      if not ok then
        vim.schedule(function()
          vim.notify(
            result,
            vim.log.levels.ERROR,
            {
              title = 'buffer.attach',
            }
          )
        end)
      end

      return false
    end
  end

  ---------------------------------------------------------------------------
  -- reload
  ---------------------------------------------------------------------------

  if opts.on_reload then
    callbacks.on_reload = function(
      _,
      changed_buf
    )
      local ok, result =
        pcall(
          opts.on_reload,
          changed_buf
        )

      if not ok then
        vim.schedule(function()
          vim.notify(
            result,
            vim.log.levels.ERROR,
            {
              title = 'buffer.attach',
            }
          )
        end)
      end
    end
  end

  ---------------------------------------------------------------------------
  -- detach
  ---------------------------------------------------------------------------

  if opts.on_detach then
    callbacks.on_detach = function(
      _,
      changed_buf
    )
      local ok, result =
        pcall(
          opts.on_detach,
          changed_buf
        )

      if not ok then
        vim.schedule(function()
          vim.notify(
            result,
            vim.log.levels.ERROR,
            {
              title = 'buffer.attach',
            }
          )
        end)
      end
    end
  end

  local ok, result = pcall(
    api.nvim_buf_attach,
    buf,
    false,
    callbacks
  )

  if not ok then
    return false
  end

  return result == true
end

-------------------------------------------------------------------------------
-- ffi information
-------------------------------------------------------------------------------

---@return boolean
function M.has_ffi_fast_path()
  return has_ffi
end

return M
