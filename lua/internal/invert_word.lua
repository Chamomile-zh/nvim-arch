local api = vim.api
local get_visual_pos = require("internal.util.get_surround").visual


local function feedkeys(keys,mode)
    api.nvim_feedkeys(api.nvim_replace_termcodes(keys,true,true,true),mode,true)
end

local defualt_word_map = {
  ['true'] = 'false',
  ['True'] = 'False',
  ['TRUE'] = 'FALSE',
  ['false'] = 'true',
  ['False'] = 'True',
  ['FALSE'] = 'TRUE',
  ['yes'] = 'no',
  ['Yes'] = 'No',
  ['YES'] = 'NO',
  ['no'] = 'yes',
  ['No'] = 'Yes',
  ['NO'] = 'YES',
  ['on'] = 'off',
  ['On'] = 'Off',
  ['ON'] = 'OFF',
  ['off'] = 'on',
  ['Off'] = 'On',
  ['OFF'] = 'ON',
  ['max'] = 'min',
  ['Max'] = 'Min',
  ['MAX'] = 'MIN',
  ['min'] = 'max',
  ['Min'] = 'Max',
  ['MIN'] = 'MAX',
  ['and'] = 'or',
  ['And'] = 'Or',
  ['AND'] = 'OR',
  ['or'] = 'and',
  ['Or'] = 'And',
  ['OR'] = 'AND',
  ['+'] = '-',
  ['+='] = '-=',
  ['-'] = '+',
  ['-='] = '+=',
  ['<'] = '>',
  ['>'] = '<',
  ['=='] = '!=',
  ['!='] = '==',
  ['<='] = '>=',
  ['>='] = '<=',
  ['&'] = '|',
  ['&&'] = '||',
  ['&='] = '|=',
  ['|'] = '&',
  ['||'] = '&&',
  ['|='] = '&=',
}

local function get_cursor_word_info()
    vim.cmd("normal! viw") -- 进入普通模式 执行viw
    local _,sr,_,er = get_visual_pos()
    feedkeys("<esc>","n")

    local word = string.sub(api.nvim_get_current_line(),sr,er)
    return word,sr,er
end

local function get_word_map()
    local word_map = {}
    local filetype = vim.bo.filetype --获取当前文件类型
    local special_map = {}

    if filetype == "lua" then
        special_map = {
            ["=="] = "~=",
            ["~="] = "=="
        }
    end

    word_map = vim.tbl_extend("force",defualt_word_map,special_map or {})
    return word_map
end

local function change_line(sr,er,word)
    local line = api.nvim_get_current_line()
    local line_front = string.sub(line,1,sr-1) -- 获取1到start row -1
    local line_back = string.sub(line,er+1) --获取end row到结尾
    api.nvim_set_current_line(line_front .. word .. line_back)


end
local function inver_word()
    -- local cursor = api.nvim_win_get_cursor(0) --获取当前cursor位置
    local oldword,sr,er = get_cursor_word_info() --start row,end row
    local word_map = get_word_map()
    if word_map[oldword] then
        change_line(sr,er,word_map[oldword])
    else
        vim.notify("Unsupport word",vim.log.levels.INFO)
    end
end

return {inver_word = inver_word}
