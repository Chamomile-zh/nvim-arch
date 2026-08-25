local M = {}
local api = vim.api

-- 书签数据将永久保存在你的 Neovim 数据目录下
local data_path = vim.fn.stdpath('data') .. '/bookmarks.json'

-- 读取书签 (同步即可，极小文件)
local function load_bookmarks()
  local f = io.open(data_path, 'r')
  if not f then return {} end
  local content = f:read('*a')
  f:close()
  if content == '' then return {} end
  local ok, data = pcall(vim.json.decode, content)
  return ok and data or {}
end

-- 保存书签
local function save_bookmarks(data)
  local f = io.open(data_path, 'w')
  if f then
    f:write(vim.json.encode(data))
    f:close()
  end
end

-- ✨ 核心功能 1：添加/取消书签
function M.toggle()
  local file = api.nvim_buf_get_name(0)
  if file == '' then
    vim.notify("Cannot bookmark an unnamed buffer", vim.log.levels.WARN)
    return
  end

  local line = api.nvim_win_get_cursor(0)[1]
  local text = vim.trim(api.nvim_get_current_line())
  local bookmarks = load_bookmarks()
  local found_idx = nil

  -- 查找当前行是否已经有书签
  for i, bm in ipairs(bookmarks) do
    if bm.file == file and bm.line == line then
      found_idx = i
      break
    end
  end

  if found_idx then
    -- 如果已存在，则移除 (Toggle)
    table.remove(bookmarks, found_idx)
    vim.notify(string.format("[-] Bookmark removed (Line %d)", line), vim.log.levels.INFO, { title = "Bookmark" })
  else
    -- 如果不存在，则添加
    table.insert(bookmarks, { file = file, line = line, text = text })
    vim.notify(string.format("[+] Bookmark added (Line %d)", line), vim.log.levels.INFO, { title = "Bookmark" })
  end

  save_bookmarks(bookmarks)
end

-- ✨ 核心功能 2：使用 Fzf-Lua 展示书签
function M.show()
  local bookmarks = load_bookmarks()

  if #bookmarks == 0 then
    vim.notify("No bookmarks found.", vim.log.levels.WARN, { title = "Bookmark" })
    return
  end

  -- 将 JSON 转换成 fzf 喜欢的标准 grep 格式： "文件绝对路径:行号:代码内容"
  local entries = {}
  for _, bm in ipairs(bookmarks) do
    -- 为了界面美观，我们可以把绝对路径转换成相对于 Home 目录的路径 (如 ~/xxx)
    local short_file = vim.fn.fnamemodify(bm.file, ":~")
    table.insert(entries, string.format("%s:%d: %s", short_file, bm.line, bm.text))
  end

  -- 呼叫 fzf-lua 神器
  require('fzf-lua').fzf_exec(entries, {
    prompt = '🔖 Bookmarks> ',
    previewer = 'builtin', -- 自动触发带语法高亮的预览窗！
    actions = {
      -- 按下回车键时，fzf-lua 会自动解析 "文件:行号" 并完美跳过去
      ['default'] = require('fzf-lua.actions').file_edit,
    },
    fzf_opts = {
      ['--no-multi'] = true, -- 禁用多选
    },
  })
end

return M
