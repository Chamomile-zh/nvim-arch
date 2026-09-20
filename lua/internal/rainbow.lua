local M = {}

local api = vim.api
local uv = vim.uv or vim.loop

local states = {}
local timers = {}
local query_cache = {}

local config = {
  debounce = 70,
  insert_debounce = 100,
  view_margin = 80,
  render_chunk = 50,
  max_lines = 10000,
}

local hl_targets = {
  'Keyword',
  'Function',
  'Type',
  'Constant',
  'String',
  'Special',
}

local ns = api.nvim_create_namespace('DIY_TSRainbow')
local match_ns = api.nvim_create_namespace('DIY_TSRainbow_Match')

local opening = {
  ['('] = true,
  ['['] = true,
  ['{'] = true,
}

local bracket_pairs = {
  ['('] = ')',
  ['['] = ']',
  ['{'] = '}',
  [')'] = '(',
  [']'] = '[',
  ['}'] = '{',
}

local query_string = '([ "(" ")" "[" "]" "{" "}" ] @bracket)'

local function apply_colors()
  for i, target in ipairs(hl_targets) do
    api.nvim_set_hl(0, 'RainbowBracket' .. i, {
      link = target,
      default = true,
    })
  end

  api.nvim_set_hl(0, 'DIY_RainbowMatch', {
    underline = true,
  })
end

local function close_timer(buf)
  local timer = timers[buf]
  if not timer then
    return
  end

  timers[buf] = nil

  pcall(function()
    timer:stop()
  end)

  pcall(function()
    if not timer:is_closing() then
      timer:close()
    end
  end)
end

local function get_query(lang)
  if query_cache[lang] ~= nil then
    return query_cache[lang] or nil
  end

  local ok, query = pcall(vim.treesitter.query.parse, lang, query_string)

  if not ok or not query then
    query_cache[lang] = false
    return nil
  end

  query_cache[lang] = query
  return query
end

local function get_visible_ranges(buf)
  local line_count = api.nvim_buf_line_count(buf)
  local ranges = {}
  local chunk = math.max(1, config.render_chunk)

  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_is_valid(win) and api.nvim_win_get_buf(win) == buf then
      local ok, view = pcall(api.nvim_win_call, win, function()
        return {
          vim.fn.line('w0'),
          vim.fn.line('w$'),
        }
      end)

      if ok and view and view[1] and view[2] then
        local start_row = math.max(0, view[1] - 1 - config.view_margin)

        local end_row = math.min(line_count - 1, view[2] - 1 + config.view_margin)

        start_row = math.floor(start_row / chunk) * chunk

        end_row = math.min(line_count - 1, math.ceil((end_row + 1) / chunk) * chunk - 1)

        ranges[#ranges + 1] = {
          start_row,
          end_row,
        }
      end
    end
  end

  if #ranges <= 1 then
    return ranges
  end

  table.sort(ranges, function(a, b)
    return a[1] < b[1]
  end)

  local merged = {
    ranges[1],
  }

  for i = 2, #ranges do
    local current = ranges[i]
    local last = merged[#merged]

    if current[1] <= last[2] + 1 then
      last[2] = math.max(last[2], current[2])
    else
      merged[#merged + 1] = current
    end
  end

  return merged
end

local function range_key(ranges)
  local parts = {}

  for i, range in ipairs(ranges) do
    parts[i] = range[1] .. ':' .. range[2]
  end

  return table.concat(parts, ',')
end

local function render_visible(buf, force)
  if not api.nvim_buf_is_valid(buf) or not api.nvim_buf_is_loaded(buf) then
    return
  end

  local state = states[buf]

  if not state or not state.bracket_map then
    return
  end

  local ranges = get_visible_ranges(buf)

  if #ranges == 0 then
    return
  end

  local key = range_key(ranges)

  if not force and state.render_key == key then
    return
  end

  api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  for _, range in ipairs(ranges) do
    for row = range[1], range[2] do
      local row_map = state.bracket_map[row]

      if row_map then
        for col, info in pairs(row_map) do
          pcall(api.nvim_buf_set_extmark, buf, ns, row, col, {
            end_row = info.end_row,
            end_col = info.end_col,

            hl_group = 'RainbowBracket' .. info.color_idx,

            priority = 110,
          })
        end
      end
    end
  end

  state.render_key = key
end

local function update_match(buf)
  if not api.nvim_buf_is_valid(buf) then
    return
  end

  api.nvim_buf_clear_namespace(buf, match_ns, 0, -1)

  if api.nvim_get_mode().mode:sub(1, 1) == 'i' then
    return
  end

  local state = states[buf]

  local map = state and state.bracket_map

  if not map then
    return
  end

  local win = api.nvim_get_current_win()

  if not api.nvim_win_is_valid(win) or api.nvim_win_get_buf(win) ~= buf then
    return
  end

  local ok, cursor = pcall(api.nvim_win_get_cursor, win)

  if not ok then
    return
  end

  local row = cursor[1] - 1

  local col = cursor[2]

  local row_map = map[row]

  if not row_map then
    return
  end

  local current = row_map[col]

  if not current then
    return
  end

  if current.match_r ~= nil and current.match_c ~= nil then
    pcall(api.nvim_buf_set_extmark, buf, match_ns, current.match_r, current.match_c, {
      end_col = current.match_c + 1,

      hl_group = 'DIY_RainbowMatch',

      priority = 120,
    })
  end
end

local function rebuild(buf, force)
  if not api.nvim_buf_is_valid(buf) or not api.nvim_buf_is_loaded(buf) then
    return
  end

  if vim.bo[buf].buftype ~= '' then
    return
  end

  local line_count = api.nvim_buf_line_count(buf)

  if line_count > config.max_lines then
    states[buf] = nil

    api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    api.nvim_buf_clear_namespace(buf, match_ns, 0, -1)

    return
  end

  local changedtick = api.nvim_buf_get_changedtick(buf)

  local old_state = states[buf]

  if not force and old_state and old_state.changedtick == changedtick then
    render_visible(buf, false)

    update_match(buf)

    return
  end

  local ok_parser, parser = pcall(vim.treesitter.get_parser, buf)

  if not ok_parser or not parser then
    return
  end

  local lang = parser:lang()

  local query = get_query(lang)

  if not query then
    return
  end

  local ok_tree, trees = pcall(function()
    return parser:parse()
  end)

  if not ok_tree or not trees or not trees[1] then
    return
  end

  local root = trees[1]:root()

  local depth = 0

  local bracket_map = {}

  local stack = {}

  for _, node in query:iter_captures(root, buf, 0, -1) do
    local ok_text, text = pcall(vim.treesitter.get_node_text, node, buf)

    if ok_text and type(text) == 'string' and bracket_pairs[text] then
      local sr, sc, er, ec = node:range()

      bracket_map[sr] = bracket_map[sr] or {}

      local info = {
        char = text,

        end_row = er,
        end_col = ec,
      }

      bracket_map[sr][sc] = info

      if opening[text] then
        depth = depth + 1

        info.color_idx = (depth - 1) % #hl_targets + 1

        stack[#stack + 1] = {
          r = sr,
          c = sc,
          char = text,
        }
      else
        info.color_idx = (depth - 1) % #hl_targets + 1

        depth = math.max(0, depth - 1)

        for i = #stack, 1, -1 do
          if stack[i].char == bracket_pairs[text] then
            local match = table.remove(stack, i)

            info.match_r = match.r

            info.match_c = match.c

            local match_row = bracket_map[match.r]

            local match_info = match_row and match_row[match.c]

            if match_info then
              match_info.match_r = sr
              match_info.match_c = sc
            end

            break
          end
        end
      end
    end
  end

  states[buf] = {
    changedtick = changedtick,

    bracket_map = bracket_map,

    render_key = nil,
  }

  render_visible(buf, true)

  update_match(buf)
end

local function schedule_update(buf, delay, force)
  if not api.nvim_buf_is_valid(buf) or not api.nvim_buf_is_loaded(buf) then
    return
  end

  if vim.bo[buf].buftype ~= '' then
    return
  end

  close_timer(buf)

  local timer = uv.new_timer()

  if not timer then
    return
  end

  timers[buf] = timer

  timer:start(
    delay or config.debounce,

    0,

    vim.schedule_wrap(function()
      if timers[buf] == timer then
        timers[buf] = nil
      end

      pcall(function()
        timer:stop()
      end)

      pcall(function()
        if not timer:is_closing() then
          timer:close()
        end
      end)

      if api.nvim_buf_is_valid(buf) and api.nvim_buf_is_loaded(buf) then
        rebuild(buf, force)
      end
    end)
  )
end

function M.refresh(buf)
  buf = buf or api.nvim_get_current_buf()

  schedule_update(buf, 0, true)
end

function M.setup(opts)
  if opts then
    config = vim.tbl_deep_extend('force', config, opts)
  end

  apply_colors()

  local augroup = api.nvim_create_augroup('DIY_TSRainbow', {
    clear = true,
  })

  api.nvim_create_autocmd('ColorScheme', {
    group = augroup,

    callback = apply_colors,
  })

  api.nvim_create_autocmd({
    'BufEnter',
    'BufWinEnter',
  }, {
    group = augroup,

    callback = function(args)
      if api.nvim_buf_is_valid(args.buf) and vim.bo[args.buf].buftype == '' then
        schedule_update(args.buf, 0, false)
      end
    end,
  })

  api.nvim_create_autocmd('TextChanged', {
    group = augroup,

    callback = function(args)
      if api.nvim_buf_is_valid(args.buf) and vim.bo[args.buf].buftype == '' then
        schedule_update(args.buf, config.debounce, false)
      end
    end,
  })

  api.nvim_create_autocmd('TextChangedI', {
    group = augroup,

    callback = function(args)
      if api.nvim_buf_is_valid(args.buf) and vim.bo[args.buf].buftype == '' then
        schedule_update(args.buf, config.insert_debounce, false)
      end
    end,
  })

  api.nvim_create_autocmd('WinScrolled', {
    group = augroup,

    callback = function(args)
      local win = tonumber(args.match) or api.nvim_get_current_win()

      if api.nvim_win_is_valid(win) then
        local buf = api.nvim_win_get_buf(win)

        if api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == '' then
          render_visible(buf, false)

          update_match(buf)
        end
      end
    end,
  })

  api.nvim_create_autocmd('CursorMoved', {
    group = augroup,

    callback = function(args)
      if api.nvim_buf_is_valid(args.buf) and vim.bo[args.buf].buftype == '' then
        update_match(args.buf)
      end
    end,
  })

  api.nvim_create_autocmd('InsertEnter', {
    group = augroup,

    callback = function(args)
      if api.nvim_buf_is_valid(args.buf) then
        api.nvim_buf_clear_namespace(args.buf, match_ns, 0, -1)
      end
    end,
  })

  api.nvim_create_autocmd('InsertLeave', {
    group = augroup,

    callback = function(args)
      if api.nvim_buf_is_valid(args.buf) and vim.bo[args.buf].buftype == '' then
        update_match(args.buf)
      end
    end,
  })

  api.nvim_create_autocmd('BufWipeout', {
    group = augroup,

    callback = function(args)
      states[args.buf] = nil

      close_timer(args.buf)
    end,
  })

  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' then
      schedule_update(buf, 0, false)
    end
  end
end

return M
