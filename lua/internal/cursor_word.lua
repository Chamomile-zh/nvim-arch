local api, expand = vim.api, vim.fn.expand
local buffer = require('internal.util.buffer')
local ns = api.nvim_create_namespace('cursor_word')
local infos = {}

--- 寻找特定单词的位置闭包
---@param str string
---@param pattern string
---@return function
local function find_pos(str, pattern)
  local start_pos = 1
  local pattern_len = #pattern -- 使用字节长度即可

  return function()
    while start_pos <= #str do
      -- 加上 true 参数表示纯文本匹配，比正则匹配更快
      local found_pos = str:find(pattern, start_pos, true)

      if not found_pos then
        return nil
      end

      -- 获取前一个和后一个字符，用于单词边界判定
      local char_before_str = str:sub(found_pos - 1, found_pos - 1)
      local char_after_str = str:sub(found_pos + pattern_len, found_pos + pattern_len)

      start_pos = found_pos + 1
      -- 判断是否是独立单词
      if (char_before_str == '' or char_before_str:match('[^%w_]'))
         and (char_after_str == '' or char_after_str:match('[^%w_]'))
      then
        -- str:find 返回的是 1-based 的字节索引
        -- extmark 需要的是 0-based 的字节索引，直接减 1 
        return found_pos - 1
      end
    end
  end
end

local function on_win(_, winid, bufnr)
  if
    bufnr ~= api.nvim_get_current_buf()
    -- 如果不限制只在 lsp_fts 里高亮，可以把下面这行注释掉
    -- or not vim.iter(lsp_fts):any(function(v) return v == vim.bo[bufnr].ft end)
    or api.nvim_get_mode().mode:find('i')
  then
    return false
  end

  infos.cword = expand('<cword>')

  local cursor_pos = api.nvim_win_get_cursor(winid)
  local current_line = buffer.get_current_line(cursor_pos[1] - 1)
  if
    not infos.cword:find('[%w%z\192-\255]')
    or not current_line:sub(cursor_pos[2] + 1, cursor_pos[2] + 1):match('[%w_]')
  then
    infos.cword = nil
    return false
  end

  api.nvim_win_set_hl_ns(winid, ns)
  infos.len = #infos.cword
end

local function on_line(_, _, bufnr, row)
  for col in find_pos(buffer.get_current_line(row), infos.cword) do
    api.nvim_buf_set_extmark(bufnr, ns, row, col, {
      end_col = col + infos.len,
      end_row = row,
      hl_group = 'CursorWord',
      ephemeral = true,
    })
  end
end

api.nvim_set_decoration_provider(ns, { on_win = on_win, on_line = on_line })
