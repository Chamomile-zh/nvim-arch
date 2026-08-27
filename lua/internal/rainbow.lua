local M = {}

function M.setup()
  local hl_targets = {
    'Keyword',
    'Function',
    'Type',
    'Constant',
    'String',
    'Special',
  }

  local function apply_colors()
    for i, target in ipairs(hl_targets) do
      vim.api.nvim_set_hl(0, 'RainbowBracket' .. i, { link = target, default = true })
    end
  end

  apply_colors()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('DIY_TSRainbow_Colors', { clear = true }),
    callback = apply_colors,
  })

  local ns = vim.api.nvim_create_namespace('DIY_TSRainbow')

  local function update_rainbow(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    local ok, parser = pcall(vim.treesitter.get_parser, buf)
    if not ok or not parser then
      return
    end

    local query_str = '([ "(" ")" "[" "]" "{" "}" ] @bracket)'
    local ok_q, query = pcall(vim.treesitter.query.parse, parser:lang(), query_str)
    if not ok_q or not query then
      return
    end

    local trees = parser:parse()
    if not trees or not trees[1] then
      return
    end
    local root = trees[1]:root()

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    local depth = 0
    local opening = { ['('] = true, ['['] = true, ['{'] = true }
    local closing = { [')'] = true, [']'] = true, ['}'] = true }

    for id, node in query:iter_captures(root, buf, 0, -1) do
      local text = vim.treesitter.get_node_text(node, buf)

      if text and opening[text] then
        depth = depth + 1
        local color_idx = (depth - 1) % #hl_targets + 1

        local sr, sc, er, ec = node:range()
        pcall(vim.api.nvim_buf_set_extmark, buf, ns, sr, sc, {
          end_row = er,
          end_col = ec,
          hl_group = 'RainbowBracket' .. color_idx,
          priority = 110,
        })
      elseif text and closing[text] then
        local color_idx = (depth - 1) % #hl_targets + 1

        local sr, sc, er, ec = node:range()
        pcall(vim.api.nvim_buf_set_extmark, buf, ns, sr, sc, {
          end_row = er,
          end_col = ec,
          hl_group = 'RainbowBracket' .. color_idx,
          priority = 110,
        })
        depth = math.max(0, depth - 1)
      end
    end
  end

  local timers = {}
  local function schedule_update(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    if vim.api.nvim_buf_line_count(buf) > 10000 then
      return
    end

    if timers[buf] then
      timers[buf]:stop()
      timers[buf]:close()
    end
    timers[buf] = vim.uv.new_timer()
    timers[buf]:start(
      100,
      0,
      vim.schedule_wrap(function()
        timers[buf] = nil
        update_rainbow(buf)
      end)
    )
  end

  vim.api.nvim_create_autocmd({ 'BufEnter', 'TextChanged', 'TextChangedI' }, {
    group = vim.api.nvim_create_augroup('DIY_TSRainbow_Syntax', { clear = true }),
    callback = function(args)
      if vim.bo[args.buf].buftype == '' then
        schedule_update(args.buf)
      end
    end,
  })

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' then
      schedule_update(buf)
    end
  end
end

return M
