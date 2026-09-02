local M = {}
local api = vim.api
local uv = vim.uv or vim.loop
local ffi = require('ffi')

pcall(
  ffi.cdef,
  [[
  char *strstr(const char *haystack, const char *needle);
]]
)

local config = {
  TODO = { bg = '#E5C07B', fg = '#282C34', icon = ' ' },
  FIXME = { bg = '#E06C75', fg = '#282C34', icon = ' ' },
  NOTE = { bg = '#98C379', fg = '#282C34', icon = ' ' },
}

local ns = api.nvim_create_namespace('DIY_Todo_FFI')
local timers = {}

local function setup_highlights()
  for kw, opts in pairs(config) do
    api.nvim_set_hl(0, 'DIYTodo_' .. kw, { fg = opts.fg, bg = opts.bg, bold = true })
    api.nvim_set_hl(0, 'DIYTodoSign_' .. kw, { fg = opts.bg })
  end
end

local function is_in_comment(buf, row, col)
  local ok, node = pcall(vim.treesitter.get_node, { bufnr = buf, pos = { row, col } })
  if not ok or not node then
    return false
  end

  while node do
    local type = node:type()
    if type:find('comment') then
      return true
    end
    node = node:parent()
  end

  return false
end

local function update_todos(buf)
  if not api.nvim_buf_is_valid(buf) then
    return
  end
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local lines = api.nvim_buf_get_lines(buf, 0, -1, false)

  for i, line in ipairs(lines) do
    -- 空行直接跳过
    if line ~= '' then
      -- 转换为 C 的字符指针
      local c_line = ffi.cast('const char*', line)

      for kw, opts in pairs(config) do
        local c_kw = ffi.cast('const char*', kw)
        local current_ptr = c_line

        while true do
          local match_ptr = ffi.C.strstr(current_ptr, c_kw)
          if match_ptr == nil then
            break
          end

          local col = tonumber(match_ptr - c_line)

          if is_in_comment(buf, i - 1, col) then
            api.nvim_buf_set_extmark(buf, ns, i - 1, col, {
              end_row = i - 1,
              end_col = col + #kw,
              hl_group = 'DIYTodo_' .. kw,
              sign_text = opts.icon,
              sign_hl_group = 'DIYTodoSign_' .. kw,
              priority = 110,
            })
          end

          current_ptr = match_ptr + #kw
        end
      end
    end
  end
end

local function schedule_update(buf)
  if not api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= '' then
    return
  end
  if timers[buf] then
    timers[buf]:stop()
    timers[buf]:close()
  end
  timers[buf] = uv.new_timer()
  timers[buf]:start(
    200,
    0,
    vim.schedule_wrap(function()
      if timers[buf] then
        timers[buf] = nil
        update_todos(buf)
      end
    end)
  )
end

local function async_update(buf)
  if not api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= '' then
    return
  end
  if timers[buf] then
    timers[buf]:stop()
    timers[buf]:close()
  end
  timers[buf] = uv.new_timer()
  timers[buf]:start(
    200,
    0,
    vim.schedule_wrap(function()
      if timers[buf] then
        timers[buf] = nil
        update_todos(buf)
      end
    end)
  )
end

local function sync_update(buf)
  if not api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= '' then
    return
  end

  pcall(function()
    local parser = vim.treesitter.get_parser(buf)
    if parser then
      parser:parse(true)
    end
  end)

  update_todos(buf)
end

function M.setup()
  setup_highlights()
  local group = api.nvim_create_augroup('DIY_Todo_FFI_Group', { clear = true })

  api.nvim_create_autocmd('ColorScheme', { group = group, callback = setup_highlights })

  api.nvim_create_autocmd({ 'BufReadPost', 'FileType' }, {
    group = group,
    callback = function(args)
      sync_update(args.buf)
    end,
  })

  api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = group,
    callback = function(args)
      async_update(args.buf)
    end,
  })

  api.nvim_create_autocmd('BufWipeout', {
    group = group,
    callback = function(args)
      if timers[args.buf] then
        pcall(function()
          timers[args.buf]:stop()
        end)
        pcall(function()
          timers[args.buf]:close()
        end)
        timers[args.buf] = nil
      end
    end,
  })

  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(buf) then
      sync_update(buf)
    end
  end
end

return M
