local win = require('internal.util.window')
local api = vim.api
local infos = {}
local float_opt = {}
local pos = 1

local function capitalize(str)
  return str:gsub('^%l', string.upper)
end

local function get_title()
  local name = capitalize(terminal)
  if infos.pid then
    return string.format(' %s : %d ', name, infos.pid)
  end
  return string.format(' %s ', name)
end

local function get_float_opt(opt)
  if opt == 1 then
    return {
      width = 0.25,
      height = 0.9,
      title = get_title(),
      relative = 'editor',
      row = 't',
      col = 'r',
    }
  end
  return {
    width = 0.7,
    height = 0.7,
    title = get_title(),
    relative = 'editor',
    row = 'c',
    col = 'c',
  }
end

local function toggle_open(bufnr)
  infos.prev_win = api.nvim_get_current_win()
  api.nvim_set_option_value('modified', false, { buf = bufnr })
  infos.bufnr, infos.winid = win
    :new_float(vim.tbl_extend('force', float_opt, { bufnr = bufnr }), true, true)
    :bufopt('bufhidden', 'hide')
    :wininfo()
  vim.cmd('startinsert')
end

local function quit_term()
  pcall(api.nvim_win_close, infos.winid, true)
  infos.winid = nil
end

local function new_term()
  if infos.winid then
    quit_term()
  end

  infos.prev_win = api.nvim_get_current_win()
  infos.pid = nil

  infos.bufnr, infos.winid =
    win:new_float(float_opt, true, true):bufopt('bufhidden', 'hide'):wininfo()
  ---@diagnostic disable-next-line: param-type-mismatch
  local job_id = vim.fn.jobstart(terminal or os.getenv('SHELL'), {
    term = true,
    on_exit = function()
      quit_term()
      infos.bufnr = nil
      infos.pid = nil
    end,
  })

  if job_id > 0 then
    -- 使用 pcall 防止进程闪退导致的抓取失败
    local ok, pid = pcall(vim.fn.jobpid, job_id)
    if ok then
      infos.pid = pid
      -- 瞬间重写窗口的 config 把标题换上去
      pcall(api.nvim_win_set_config, infos.winid, { title = get_title() })
    end
  end
end

local function toggle_term(opt)
  if opt == 'pos' then
    quit_term()
    float_opt = get_float_opt(pos)
    pos = 1 - pos
    toggle_open(infos.bufnr)
    return
  end
  if opt == 'focus' then
    if not infos.winid or not api.nvim_win_is_valid(infos.winid) then
      return -- 终端没打开，不做任何操作
    end

    local cur_win = api.nvim_get_current_win()
    if cur_win == infos.winid then
      -- 当前在终端里：跳回之前的代码窗口
      if infos.prev_win and api.nvim_win_is_valid(infos.prev_win) then
        api.nvim_set_current_win(infos.prev_win)
      else
        vim.cmd('wincmd p') -- 兜底方案
      end
      vim.cmd('stopinsert') -- 退出终端的插入模式
    else
      -- 当前在代码里：重新聚焦到悬浮终端
      infos.prev_win = cur_win
      api.nvim_set_current_win(infos.winid)
      vim.cmd('startinsert') -- 进入终端立刻进入插入模式
    end
    return
  end
  if opt == 'kill' then
    if infos.bufnr and api.nvim_buf_is_valid(infos.bufnr) then
      -- 1. 如果窗口还在，先安全关闭窗口
      if infos.winid and api.nvim_win_is_valid(infos.winid) then
        pcall(api.nvim_win_close, infos.winid, true)
      end
      -- 2. 强制删除终端 Buffer（这会立刻杀死底层进程）
      pcall(api.nvim_buf_delete, infos.bufnr, { force = true })
    end
    -- 3. 彻底清空所有状态，下次打开就像刚启动一样
    infos.bufnr = nil
    infos.winid = nil
    infos.pid = nil
    -- vim.notify('Terminal process killed.', vim.log.levels.WARN)
    return
  end

  if infos.bufnr == nil then
    float_opt = get_float_opt()
    new_term()
    return
  end

  if infos.winid then
    quit_term()
  else
    toggle_open(infos.bufnr)
  end
end

return { toggle_term = toggle_term }
