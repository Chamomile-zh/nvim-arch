local win = require('internal.util.window')
local command = require('internal.code_running.code_running_commands').get_commands()
local api = vim.api
local infos = {}

---Expand the $filename / $runfile / $workspace placeholders of a spec.
---@param args string
---@param ctx table {filename: string, runfile: string, workspace: string}
---@return table? opt {command: string, modus: string}
local function get_commands(args, ctx)
  local opt = vim.deepcopy(command[args])

  if not opt then
    return opt
  end

  local cmd = type(opt.command) == 'table' and table.concat(opt.command, ' && ') or opt.command

  -- zig: prefer the build system when the project has one
  if args == 'zig' and vim.fn.findfile('build.zig', '.;') ~= '' then
    cmd = 'zig build run'
  end

  -- rust: Cargo projects go through cargo, single files fall back to rustc
  if (args == 'rust' or args == 'rust_build') and vim.fn.findfile('Cargo.toml', '.;') ~= '' then
    cmd = args == 'rust' and 'cargo run' or 'cargo build --release'
  end

  -- function replacements keep '%' and other magic chars from paths intact
  opt.command = cmd
    :gsub('%$filename', function()
      return ctx.filename
    end)
    :gsub('%$runfile', function()
      return ctx.runfile
    end)
    :gsub('%$workspace', function()
      return ctx.workspace
    end)

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
    local success, pid = pcall(vim.fn.jobpid, chan_id)
    if success then
      api.nvim_win_set_config(infos.winid, {
        title = string.format(' Code Runner: %d ', pid),
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
  vim.cmd('silent! w')

  local center = false
  args, center = split_by_last_space(args)
  args = #args == 0 and vim.bo.filetype or args

  -- resolve everything against the source buffer before the float shows up
  local name = api.nvim_buf_get_name(0)
  local ctx = {
    filename = vim.fn.fnamemodify(name, ':t'),
    runfile = vim.fn.fnamemodify(name, ':t:r'),
    dir = vim.fn.fnamemodify(name, ':p:h'),
    workspace = vim.lsp.buf.list_workspace_folders()[1] or '',
  }

  local opt = get_commands(args, ctx)
  local modus = opt and opt.modus or nil
  center = center or modus == 'center'

  -- the old prompt line, pre-filled with the whole command so it can be
  -- edited in place: <CR> runs, <Esc> cancels
  vim.ui.input({
    prompt = ' Code Runner: ',
    default = opt and opt.command or '',
  }, function(input)
    if input == nil then
      return
    end

    input = vim.trim(input)
    if input == '' then
      return
    end

    local workpath = vim.fn.getcwd()

    -- run inside the buffer's directory so relative paths keep working
    vim.cmd('silent! lcd ' .. vim.fn.fnameescape(ctx.dir))

    if modus == 'job' then
      vim.fn.jobstart(input, { cwd = ctx.dir })
    elseif modus == 'cmd' then
      vim.cmd(input)
    else
      running_window(input, center)
    end

    vim.cmd('silent! lcd ' .. vim.fn.fnameescape(workpath))
  end)
end

return { running = running }
