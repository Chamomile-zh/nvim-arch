local get_surround = require('internal.util.get_surround')
local pchar = { '/', '#' }

local function check(oldword, newword)
  if oldword == '' or newword == '' then
    vim.cmd('normal! v')
    return true
  end
  return false
end

--- 提取视觉选中区域内的所有独立单词（去重）
local function get_visual_words(sl, sr, el, er)
  local seen = {}
  local words = {}
  local pattern = '[%w_]+' -- 和光标单词高亮规则一致：字母/数字/下划线

  for lnum = sl, el do
    local line = vim.fn.getline(lnum)
    local start_col = 1
    local end_col = #line

    -- 首尾行按选中范围截断
    if lnum == sl then start_col = sr end
    if lnum == el then end_col = er end

    local text = line:sub(start_col, end_col)
    for word in text:gmatch(pattern) do
      if not seen[word] then
        seen[word] = true
        table.insert(words, word)
      end
    end
  end
  return words
end

-- 全局补全函数：完全用Lua实现，供v:lua调用
_G.SubstituteWordComplete = function(ArgLead, CmdLine, CursorPos)
  local words = _G._substitute_complete_words or {}
  local matches = {}
  for _, word in ipairs(words) do
    -- 前缀匹配，和原生补全行为一致
    if vim.startswith(word, ArgLead) then
      table.insert(matches, word)
    end
  end
  return matches
end

--- 注册补全单词列表
local function register_word_completion(words)
  _G._substitute_complete_words = words
end

---同步获取输入，带单词补全
local function input_str(oldword, completion_words)
  if not oldword then
    if completion_words and #completion_words > 0 then
      register_word_completion(completion_words)
      -- 调用全局Lua函数作为补全源，避免v:lua变量访问问题
      oldword = vim.fn.input('Enter word old: ', '', 'customlist,v:lua.SubstituteWordComplete')
    else
      oldword = vim.fn.input('Enter word old: ')
    end
  end

  local newword = vim.fn.input('Enter word new: ')
  local char = '/'
  local vis = true
  for _, c in ipairs(pchar) do
    if not oldword:find(c,1,true) and not newword:find(c,1,true) then
      char = c
      vis = false
      break
    end
  end
  if vis then
    char = vim.fn.input('Enter char: ')
  end

  return oldword, newword, char
end

local function quick_substitute()
  local getpos = get_surround.visual
  if vim.fn.mode() == 'v' or vim.fn.mode() == 'V' then
    local sl, sr, el, er = getpos()
    local oldword, newword, char

    if sl == el then
      oldword = vim.fn.getline(sl):sub(sr, er)
      oldword, newword, char = input_str(oldword)
    else
      local words = get_visual_words(sl, sr, el, er)
      oldword, newword, char = input_str(nil, words)
    end

    if check(oldword, newword) then return end

    local cmd_opt
    if sl == el then
      cmd_opt = string.format(':s%s%s%s%s%sg', char, oldword, char, newword, char)
    else
      cmd_opt = string.format(':%d,%ds%s%s%s%s%sg', sl, el, char, oldword, char, newword, char)
    end

    vim.cmd(cmd_opt)
    vim.cmd('normal! v')
    vim.cmd('noh')
  end
end

return { quick_substitute = quick_substitute }
