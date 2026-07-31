local api = vim.api

local function get_diagnostic_signs(bufnr, lnum)
  local diagnostic = vim.diagnostic.get(bufnr, { lnum = lnum })
  if #diagnostic == 0 then
    return '  '
  end
  return ('%%#%s#%s%%*'):format(
    'Diagnostic' .. vim.diagnostic.severity[diagnostic[1].severity],
    diagnostic_signs[diagnostic[1].severity]
  )
end

local function show_break(lnum, virtnum)
  if virtnum > 0 then
    return (' '):rep(math.floor(math.ceil(math.log10(lnum))) - 1) .. '┆'
  end
  -- return virtnum < 0 and '' or lnum
  if virtnum < 0 then
    return ''
  end
  local winid=vim.g.statusline_winid

  local has_number=vim.wo[winid].number
  local has_relnum=vim.wo[winid].relativenumber

  if not has_number then
    return ''
  end
  local num_text
  if has_relnum then
    local cursor_lnum=api.nvim_win_get_cursor(winid)[1]
    local rel = math.abs(lnum-cursor_lnum)
    num_text = rel == 0 and tostring(lnum) or tostring(rel)
  else
    num_text = tostring(lnum)
  end

  local bufnr=api.nvim_win_get_buf(winid)
  local total_line=api.nvim_buf_line_count(bufnr)
  local num_width=math.floor(math.log10(total_line)+1)
  return string.format('%'  .. num_width ..'s',num_text)
end

local function get_git_signs(bufnr, lnum)
  local mark = vim
    .iter(
      api.nvim_buf_get_extmarks(
        bufnr,
        -1,
        { lnum, 0 },
        { lnum, -1 },
        { details = true, type = 'sign' }
      )
    )
    :find(function(item)
      return item[2] == lnum and item[4].sign_hl_group and item[4].sign_hl_group:find('GitSign')
    end)
  return not mark and '  ' or ('%%#%s#%s%%*'):format(mark[4].sign_hl_group, mark[4].sign_text)
end

local function stc()
  local bufnr = api.nvim_win_get_buf(vim.g.statusline_winid)
  local lnum, virtnum = vim.v.lnum, vim.v.virtnum
  return ('%s%%=%s%s'):format(
    get_diagnostic_signs(bufnr, lnum - 1),
    show_break(lnum, virtnum),
    get_git_signs(bufnr, lnum - 1)
  )
end

return { stc = stc }
