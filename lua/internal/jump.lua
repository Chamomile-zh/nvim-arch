-- High-performance in-memory fast jump based on LuaJIT FFI
local M = {}
local api, FORWARD, BACKWARD = vim.api, 1, -1

local ffi = require('ffi')
ffi.cdef([[
  typedef int32_t linenr_T;
  char *ml_get(linenr_T lnum);
]])
local ml_get = ffi.C.ml_get

local state = {
  active = false,
  ns_id = api.nvim_create_namespace('jumpmotion'),
  key_map = {},
  max_targets = 60,
}

local function cleanup()
  if state.active then
    api.nvim_buf_clear_namespace(0, state.ns_id, 0, -1)
    state.active = false
    state.key_map = {}
  end
end

local function generate_keys(count)
  local keys = 'asdghjklzxcvbnmqwertyuiopASDGHJLZXCVBNMQWERTYUIOP1234567890'
  local result = {}
  for i = 1, math.min(count, #keys) do
    table.insert(result, keys:sub(i, i))
  end
  return result
end

local function dim_buffer(first_line, last_line)
  for lnum = first_line, last_line do
    local ptr = ml_get(lnum + 1)
    if ptr ~= nil and tonumber(ffi.cast("intptr_t",ptr)) ~= 0 then
      local len = #ffi.string(ptr)
      if len > 0 then
        api.nvim_buf_set_extmark(0, state.ns_id, lnum, 0, {
          end_col = len,
          hl_group = 'JumpMotionDim',
          priority = 200,
        })
      end
    end
  end
end

local function mark_targets(targets, first_line, last_line)
  api.nvim_buf_clear_namespace(0, state.ns_id, 0, -1)
  dim_buffer(first_line, last_line)

  local keys = generate_keys(#targets)
  state.key_map = {}

  for i, target in ipairs(targets) do
    if i > #keys then break end
    local key = keys[i]
    state.key_map[key] = target

    api.nvim_buf_set_extmark(0, state.ns_id, target.row, target.col, {
      end_col = target.col + 1,
      hl_group = 'JumpMotionTargetBg',
      priority = 250,
    })

    api.nvim_buf_set_extmark(0, state.ns_id, target.row, target.col, {
      virt_text = { { key, 'JumpMotionTarget' } },
      virt_text_pos = 'overlay',
      priority = 300,
    })
  end

  vim.cmd('redraw')

  local ok, char = pcall(function()
    return vim.fn.nr2char(vim.fn.getchar())
  end)

  if ok and char and char ~= '' and char ~= '\27' then
    local target = state.key_map[char]
    if target then
      api.nvim_win_set_cursor(0, { target.row + 1, target.col })
    end
  end

  cleanup()
end

function M.char(direction)
  return function()
    if state.active then cleanup() end

    -- 同步读取输入字符
    local ok, char = pcall(function()
      return vim.fn.nr2char(vim.fn.getchar())
    end)
    if not ok or not char or char == '' or char == '\27' or char == ' ' then
      return
    end

    state.active = true
    local first_line = vim.fn.line('w0') - 1
    local last_line = vim.fn.line('w$') - 1
    local cursor = api.nvim_win_get_cursor(0)
    local curow = cursor[1] - 1
    local curcol = cursor[2]

    local targets = {}
    local start_l = (direction == FORWARD) and curow or curow
    local end_l = (direction == FORWARD) and last_line or first_line
    local step = (direction == FORWARD) and 1 or -1

    for lnum = start_l, end_l, step do
      local ptr = ml_get(lnum + 1)
      if ptr ~= nil and tonumber(ffi.cast("intptr_t",ptr)) ~= 0 then
        local line_str = ffi.string(ptr)
        local start_c = 1

        -- 如果是光标所在行，正向跳过光标前，反向跳过光标后
        if lnum == curow then
          if direction == FORWARD then
            start_c = curcol + 2
          end
        end

        local col_idx = line_str:find(char, start_c, true)
        while col_idx do
          -- 反向搜索时光标同行的边界防护
          if not (lnum == curow and direction == BACKWARD and (col_idx - 1) >= curcol) then
            table.insert(targets, { row = lnum, col = col_idx - 1 })
            if #targets >= state.max_targets then break end
          end
          col_idx = line_str:find(char, col_idx + 1, true)
        end
      end
      if #targets >= state.max_targets then break end
    end

    if #targets == 0 then
      cleanup()
      return
    end

    mark_targets(targets, first_line, last_line)
  end
end

api.nvim_set_hl(0, 'JumpMotionTarget', { link = 'Function' })
api.nvim_set_hl(0, 'JumpMotionDim', { link = 'Comment' })

return { charForward = M.char(FORWARD), charBackward = M.char(BACKWARD) }
