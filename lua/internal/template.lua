local api = vim.api
local fn = vim.fn

local M = {}

local default_config = {
  template_dir = fn.expand('~/.config/nvim/template'),
  auto_format = false,
  auto_filter_by_ft = false,
}

local config = {}

local function read_file(path)
  local f = io.open(path, 'r')
  if not f then
    return ''
  end
  local content = f:read('*a')
  f:close()
  return content
end

local function insert_content(content)
  local bufnr = api.nvim_get_current_buf()
  local row, col = unpack(api.nvim_win_get_cursor(0))
  local lines = vim.split(content, '\n')
  api.nvim_buf_set_text(bufnr, row - 1, col, row - 1, col, lines)
  if config.auto_format then
    vim.cmd('normal! =' .. #lines .. 'j')
  end
end

function M.insert_template()
  local dir = config.template_dir
  if fn.isdirectory(dir) == 0 then
    vim.notify('模板目录不存在: ' .. dir, vim.log.levels.ERROR)
    return
  end

  if not package.loaded['fzf-lua'] then
    vim.cmd.packadd('fzf-lua')
  end

  require('fzf-lua').files({
    prompt = 'Templates> ',
    cwd = dir,
    previewer = 'builtin',
    actions = {
      ['default'] = function(selected, opts)
        if not selected or #selected == 0 then
          return
        end
        local file = dir .. '/' .. selected[1]
        local content = read_file(file)
        if content == '' then
          vim.notify('模板读取失败', vim.log.levels.WARN)
          return
        end
        insert_content(content)
        vim.notify('已插入: ' .. selected[1])
      end,
    },
  })
end

function M.setup(opts)
  config = vim.tbl_deep_extend('force', default_config, opts or {})
  api.nvim_create_user_command('Template', function()
    M.insert_template()
  end, { desc = 'FzfLua 选择并插入模板' })
end

return M
