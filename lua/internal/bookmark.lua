local M = {}
local api = vim.api

-- 书签数据将保存在你的 Neovim 数据目录下
local data_path = vim.fn.stdpath('data') .. '/bookmarks.json'

-- 读取书签
local function load_bookmarks()
  local f = io.open(data_path, 'r')
  if not f then
    return {}
  end
  local content = f:read('*a')
  f:close()
  if content == '' then
    return {}
  end
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

-- 添加/取消书签
function M.toggle()
  local file = api.nvim_buf_get_name(0)
  if file == '' then
    vim.notify('Cannot bookmark an unnamed buffer', vim.log.levels.WARN)
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
    vim.notify(
      string.format('[-] Bookmark removed (Line %d)', line),
      vim.log.levels.INFO,
      { title = 'Bookmark' }
    )
  else
    -- 如果不存在，则添加
    table.insert(bookmarks, { file = file, line = line, text = text })
    vim.notify(
      string.format('[+] Bookmark added (Line %d)', line),
      vim.log.levels.INFO,
      { title = 'Bookmark' }
    )
  end

  save_bookmarks(bookmarks)
end

-- 使用 Fzf-Lua 展示书签
function M.show()
  local bookmarks = load_bookmarks()

  if #bookmarks == 0 then
    vim.notify('No bookmarks found.', vim.log.levels.WARN, { title = 'Bookmark' })
    return
  end

  -- 不传静态数组，而是传一个动态回调生成器
  local function bookmark_provider(cb)
    -- 每次 fzf 刷新时，都会实时去硬盘拉取最新数据
    local current_bms = load_bookmarks()
    for _, bm in ipairs(current_bms) do
      local short_file = vim.fn.fnamemodify(bm.file, ':~')
      -- 逐行推给 fzf 界面
      cb(string.format('%s:%d: %s', short_file, bm.line, bm.text))
    end
    -- 传入 nil 告诉 fzf 当前数据推送完毕
    cb(nil)
  end

  if not package.loaded['fzf-lua'] then
    vim.cmd.packadd('fzf-lua')
  end

  require('fzf-lua').fzf_exec(bookmark_provider, {
    prompt = '🔖 Bookmarks> ',
    previewer = 'builtin',
    fzf_opts = {
      ['--no-multi'] = true,
      ['--header'] = ':: [Enter] Edit | [Ctrl-D] Delete',
    },
    actions = {
      -- 默认动作：回车跳转
      ['default'] = require('fzf-lua.actions').file_edit,

      -- 定义组合 Action (包含热重载标记)
      ['ctrl-d'] = {
        fn = function(selected, opts)
          if not selected or #selected == 0 then
            return
          end
          local entry = selected[1]

          local short_file, line_str = entry:match('^(.-):(%d+):')
          if not short_file or not line_str then
            return
          end

          local abs_file = vim.fn.expand(short_file)
          local target_line = tonumber(line_str)

          local bms = load_bookmarks()
          local new_bookmarks = {}
          for _, bm in ipairs(bms) do
            if bm.file == abs_file and bm.line == target_line then
              -- 丢弃该项
            else
              table.insert(new_bookmarks, bm)
            end
          end

          save_bookmarks(new_bookmarks)
          vim.notify(
            string.format('[-] Bookmark deleted (Line %d)', target_line),
            vim.log.levels.INFO
          )
        end,
        -- 告诉 fzf-lua 执行完函数后不要关闭窗口，而是原地重新调用 bookmark_provider！
        reload = true,
      },
    },
  })
end

return M
