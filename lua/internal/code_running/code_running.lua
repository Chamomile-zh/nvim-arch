local win = require('internal.util.window')
local command = require('internal.code_running.code_running_commands').get_commands()
local api, expand = vim.api, vim.fn.expand
local infos = {}


---get running command and running modus by filetype
---@param args string
---@param extra_args string? 用户在 vim.ui.input 中输入的额外参数
---@return table {command: string, modus: string}
local function get_commands(args, extra_args)
  local filename = expand('%')
  local runfile = expand('%<')
  local workspace = vim.lsp.buf.list_workspace_folders()[1] or ''

  local opt = vim.deepcopy(command[args])

  if not opt then
    return opt
  end

  if type(opt.command) == 'table' then
    --  如果有额外参数，精准追加到表的第一条命令（通常是编译命令）
    if extra_args and extra_args ~= '' then
      opt.command[1] = opt.command[1] .. ' ' .. extra_args
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    opt.command = table.concat(opt.command, ' && ')
  else
    -- 如果原本就是单条命令的字符串，直接追加在最后
    if extra_args and extra_args ~= '' then
      opt.command = opt.command .. ' ' .. extra_args
    end
  end

  opt.command =
    opt.command:gsub('$filename', filename):gsub('$runfile', runfile):gsub('$workspace', workspace)

  return opt
end

---get the float terminal infos
---@param center boolean
---@return table
local function get_float_opt(center)
  return {
    width = center and 0.7 or 0.25,
    height = center and 0.5 or 0.9,
    relative = 'editor',
    row = center and 'c' or 't',
    col = center and 'c' or 'r',
  }
end

---create float window to running the command
---@param opt string
---@param center boolean
local function running_window(opt, center)
  local float_opt = get_float_opt(center)

  infos.bufnr, infos.winid =
    win:new_float(float_opt, true, true):bufopt('bufhidden', 'hide'):wininfo()

  api.nvim_create_autocmd('WinClosed', {
    buffer = infos.bufnr,
    callback = function()
      if infos.winid and api.nvim_win_is_valid(infos.winid) then
        api.nvim_win_close(infos.winid, true)
      end
      api.nvim_buf_delete(infos.bufnr, { force = true })
      infos.winid = nil
    end,
  })

  vim.cmd.term(opt)

  local chan_id = vim.b[infos.bufnr].terminal_job_id

  if chan_id then
    local success,pid = pcall(vim.fn.jobpid, chan_id)
    if success then
      api.nvim_win_set_config(infos.winid,{
        title = string.format(' Code Running: %d ', pid)
      })
    end
  end

  api.nvim_create_autocmd('TermClose', {
    buffer = infos.bufnr,
    callback = function()
      vim.schedule(function()
        vim.cmd('stopinsert')
      end)
      vim.keymap.set(
        'n',
        'q',
        '<Cmd>bd!<CR>',
        { buffer = infos.bufnr, silent = true, noremap = true }
      )
    end,
  })
end

---split a string by last space
---@param str string
---@return string
---@return boolean
local function split_by_last_space(str)
  local last_space = str:match('.*()%s')

  if not last_space then
    if str == 'center' then
      return '', true
    else
      return str, false
    end
  end

  local first_part = str:sub(1, last_space - 1)
  local second_part = str:sub(last_space + 1) == 'center'

  return first_part, second_part
end


---quick running code
---@param args string
local function running(args)
  vim.cmd('w')

  local workpath = vim.fn.getcwd()
  local center = false
  args, center = split_by_last_space(args)
  args = #args == 0 and vim.bo.filetype or args

  --  调出输入框
  vim.ui.input({ prompt = 'Extra args (Enter to skip): ' }, function(input)
    -- 如果用户按了 <Esc> 取消输入，input 为 nil，直接退出执行
    if input == nil then
      return
    end

    -- 将切换目录和执行逻辑放入回调内部，确保输入完成后才执行
    vim.cmd('silent! lcd %:p:h')

    -- 将用户的输入传入 get_commands
    local opt = get_commands(args, input)
    if opt then
      if opt.modus == 'job' then
        vim.fn.jobstart(opt.command)
      elseif opt.modus == 'cmd' then
        vim.cmd(opt.command)
      else
        center = center or opt.modus == 'center'
        running_window(opt.command, center)
      end
    else
      vim.notify(string.format("%s's running command is undefined\n", args), vim.log.levels.WARN)
    end

    vim.cmd('silent! lcd ' .. workpath)
  end)
end

return { running = running }
