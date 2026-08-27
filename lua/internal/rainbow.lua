local M = {}

local global_bracket_maps = {}

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
      -- reverse = true,
      underline = true,
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

    local map = global_bracket_maps[buf]
    if not map then
      return
    end

    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local r, c = cursor[1] - 1, cursor[2]

    if not map[r] then
      return
    end

    local cur_b = map[r][c]
    if not cur_b then
      return
    end

    if cur_b.match_r and cur_b.match_c then
      pcall(vim.api.nvim_buf_set_extmark, buf, match_ns, cur_b.match_r, cur_b.match_c, {
        end_col = cur_b.match_c + 1,
        hl_group = 'DIY_RainbowMatch',
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

    local map_cache = {}

    local stack = {}

    for id, node in query:iter_captures(root, buf, 0, -1) do
      local text = vim.treesitter.get_node_text(node, buf)
      local sr, sc, er, ec = node:range()

      map_cache[sr] = map_cache[sr] or {}

      local b_info = { char = text }
      map_cache[sr][sc] = b_info

      if opening[text] then
        depth = depth + 1
        local color_idx = (depth - 1) % #hl_targets + 1
        b_info.color_idx = color_idx

        table.insert(stack, { r = sr, c = sc, char = text })

        pcall(vim.api.nvim_buf_set_extmark, buf, ns, sr, sc, {
          end_row = er,
          end_col = ec,
          hl_group = 'RainbowBracket' .. color_idx,
          priority = 110,
        })
      elseif pairs[text] then
        local color_idx = (depth - 1) % #hl_targets + 1
        pcall(vim.api.nvim_buf_set_extmark, buf, ns, sr, sc, {
          end_row = er,
          end_col = ec,
          hl_group = 'RainbowBracket' .. color_idx,
          priority = 110,
        })
        depth = math.max(0, depth - 1)

        for i = #stack, 1, -1 do
          if stack[i].char == pairs[text] then
            local match = table.remove(stack, i)
            b_info.match_r = match.r
            b_info.match_c = match.c
            map_cache[match.r][match.c].match_r = sr
            map_cache[match.r][match.c].match_c = sc
            break
          end
        end
      end
    end

    global_bracket_maps[buf] = map_cache
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
      50,
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

  vim.api.nvim_create_autocmd('BufWipeout', {
    group = augroup,
    callback = function(args)
      global_bracket_maps[args.buf] = nil
    end,
  })
end

return M
