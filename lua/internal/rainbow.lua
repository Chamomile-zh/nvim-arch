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
    vim.api.nvim_set_hl(0, 'DIY_RainbowMatch', {
      bold = true,
      underline = true,
      reverse = true,
    })
  end

  apply_colors()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('DIY_TSRainbow_Colors', { clear = true }),
    callback = apply_colors,
  })

  local ns = vim.api.nvim_create_namespace('DIY_TSRainbow')
  local match_ns = vim.api.nvim_create_namespace('DIY_TSRainbow_Match')

  local opening = { ['('] = true, ['['] = true, ['{'] = true }
  local pairs = { ['('] = ')', ['['] = ']', ['{'] = '}', [')'] = '(', [']'] = '[', ['}'] = '{' }

  local function update_match(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    vim.api.nvim_buf_clear_namespace(buf, match_ns, 0, -1)

    local brackets = vim.b[buf].diy_brackets
    if not brackets or #brackets == 0 then
      return
    end

    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local r, c = cursor[1] - 1, cursor[2]
    local mode = vim.fn.mode():sub(1, 1)

    local check_cols = mode == 'i' and { c, c - 1 } or { c }
    local current_idx = nil

    for _, col in ipairs(check_cols) do
      if col < 0 then
        goto continue
      end
      local left, right = 1, #brackets
      while left <= right do
        local mid = math.floor((left + right) / 2)
        local b = brackets[mid]
        if b.r == r and b.c == col then
          current_idx = mid
          break
        elseif b.r < r or (b.r == r and b.c < col) then
          left = mid + 1
        else
          right = mid - 1
        end
      end
      if current_idx then
        break
      end
      ::continue::
    end

    if not current_idx then
      return
    end

    local cur_b = brackets[current_idx]
    local target_char = pairs[cur_b.char]
    local match_b = nil
    local depth = 1

    if opening[cur_b.char] then
      for i = current_idx + 1, #brackets do
        if brackets[i].char == cur_b.char then
          depth = depth + 1
        elseif brackets[i].char == target_char then
          depth = depth - 1
          if depth == 0 then
            match_b = brackets[i]
            break
          end
        end
      end
    else
      for i = current_idx - 1, 1, -1 do
        if brackets[i].char == cur_b.char then
          depth = depth + 1
        elseif brackets[i].char == target_char then
          depth = depth - 1
          if depth == 0 then
            match_b = brackets[i]
            break
          end
        end
      end
    end

    if match_b then
      local hl_group = 'DIY_RainbowMatch'
      -- 不修改当前的光标位置,就注释掉这里
      pcall(vim.api.nvim_buf_set_extmark, buf, match_ns, cur_b.r, cur_b.c, {
        end_col = cur_b.c + 1,
        hl_group = hl_group,
        priority = 120,
      })
      pcall(vim.api.nvim_buf_set_extmark, buf, match_ns, match_b.r, match_b.c, {
        end_col = match_b.c + 1,
        hl_group = hl_group,
        priority = 120,
      })
    end
  end

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
    local brackets_cache = {}

    for id, node in query:iter_captures(root, buf, 0, -1) do
      local text = vim.treesitter.get_node_text(node, buf)
      local sr, sc, er, ec = node:range()

      table.insert(brackets_cache, { r = sr, c = sc, char = text })

      if text and opening[text] then
        depth = depth + 1
        local color_idx = (depth - 1) % #hl_targets + 1
        pcall(vim.api.nvim_buf_set_extmark, buf, ns, sr, sc, {
          end_row = er,
          end_col = ec,
          hl_group = 'RainbowBracket' .. color_idx,
          priority = 110,
        })
      elseif text and pairs[text] then
        local color_idx = (depth - 1) % #hl_targets + 1
        pcall(vim.api.nvim_buf_set_extmark, buf, ns, sr, sc, {
          end_row = er,
          end_col = ec,
          hl_group = 'RainbowBracket' .. color_idx,
          priority = 110,
        })
        depth = math.max(0, depth - 1)
      end
    end

    vim.b[buf].diy_brackets = brackets_cache
    update_match(buf)
  end

  local timers = {}
  local function schedule_update(buf)
    if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_buf_line_count(buf) > 10000 then
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

  local augroup = vim.api.nvim_create_augroup('DIY_TSRainbow_Syntax', { clear = true })

  vim.api.nvim_create_autocmd({ 'BufEnter', 'TextChanged', 'TextChangedI' }, {
    group = augroup,
    callback = function(args)
      if vim.bo[args.buf].buftype == '' then
        schedule_update(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'InsertLeave' }, {
    group = augroup,
    callback = function(args)
      if vim.bo[args.buf].buftype == '' then
        update_match(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd('InsertEnter', {
    group = augroup,
    callback = function(args)
      if vim.api.nvim_buf_is_valid(args.buf) then
        vim.api.nvim_buf_clear_namespace(args.buf, match_ns, 0, -1)
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
