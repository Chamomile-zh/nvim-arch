local api = vim.api
local win = require('internal.util.window')
local infos = {}

local float_opt = {
  width = 0.7,
  height = 0.7,
  title = ' Lazygit ',
  relative = 'editor',
  row = 'c',
  col = 'c',
}

local uv = vim.uv or vim.loop

local function lazygit()
  infos.workpath = vim.fn.getcwd()

  if infos.bufnr and api.nvim_buf_is_valid(infos.bufnr) then
    float_opt.bufnr = infos.bufnr
    api.nvim_set_option_value('modified', false, { buf = infos.bufnr })
  else
    float_opt.bufnr = nil
  end

  infos.bufnr, infos.winid =
    win:new_float(float_opt, true, true):bufopt('bufhidden', 'hide'):wininfo()

  local check_timer = uv.new_timer()
  if check_timer then
    check_timer:start(
      500,
      500,
      vim.schedule_wrap(function()
        vim.cmd('silent! checktime')
      end)
    )
  end

  vim.fn.jobstart('lazygit', {
    term = true,
    cwd = infos.workpath,
    on_exit = function()
      if check_timer then
        pcall(function()
          check_timer:stop()
        end)
        pcall(function()
          check_timer:close()
        end)
      end

      if infos.winid and api.nvim_win_is_valid(infos.winid) then
        api.nvim_win_close(infos.winid, true)
      end
      infos.winid = nil

      vim.cmd('silent! checktime')
    end,
  })
end
return { lazygit = lazygit }
