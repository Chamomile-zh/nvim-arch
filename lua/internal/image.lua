---检查剪贴板中是否包含 PNG 图片
---@return boolean
local function check_have_img()
  -- wl-paste --list-types 会列出当前剪贴板中数据的所有 MIME 类型
  local types = vim.fn.system('wl-paste --list-types')
  if types == nil or types == '' then
    return false
  end
  -- 查找是否包含 image/png
  if string.find(types, 'image/png') then
    return true
  end
  return false
end

local function paste()
  -- 获取当前文件所在目录，并拼接 /img/
  local path = vim.fn.expand('%:p:h') .. '/img/'

  -- 如果没有 img 文件夹，自动创建
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, 'p')
  end

  if check_have_img() then
    local imagename = vim.fn.input('Enter image name: ')

    if vim.trim(imagename) == '' then
      vim.notify(' Image paste canceled.', vim.log.levels.INFO)
      return
    end

    local cmd = string.format("wl-paste --type image/png > '%s%s.png'", path, imagename)
    vim.fn.system(cmd)

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local line_before = string.sub(line, 0, col)
    local line_end = string.sub(line, col + 1)

    line = line_before .. '![](./img/' .. imagename .. '.png)' .. line_end
    vim.api.nvim_set_current_line(line)

    -- 光标定位到 [] 括号中间，并进入插入模式
    vim.api.nvim_win_set_cursor(0, { row, col + 2 })
    vim.cmd('startinsert')
  else
    vim.notify('No image found in clipboard!', vim.log.levels.WARN)
  end
end

return { paste = paste }
