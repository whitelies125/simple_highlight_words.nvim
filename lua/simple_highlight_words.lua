local colors = { "#8CCBEA", "#A4E57E", "#FFDB72", "#FF7272", "#FFB3FF", "#9999FF", "#FA9425", "#C49791" }
local highlight_prefix = "simple_hightlight_"
for index, color in ipairs(colors) do
    --[[
    nvim_set_hl({ns_id}, {name}, {*val})
    name: 高亮组名
    val:
        background: 设置用于高亮字符串的背景方框的颜色
        foreground: 设置高亮后的字符串字体的颜色，这里设为黑色，避免 background 色与字体原本颜色相近导致看不清
    --]]
    vim.api.nvim_set_hl(0, highlight_prefix .. index, { background = color, foreground = "Black"})
end

local hightlight_id_set = {}
local color_group_index = 1

local function highlight(word, pattern)
    -- 防止在空行使用该函数
    if word == '' then return end
    if hightlight_id_set[word] then
        -- disable hightlight
        vim.fn.matchdelete(hightlight_id_set[word])
        hightlight_id_set[word] = nil;
        return
    end
    --[[
    matchadd({group}, {pattern},...)
    将符合 pattern 的字符串加入 group 高亮组
    --]]
    local id = vim.fn.matchadd(highlight_prefix .. color_group_index, pattern)
    hightlight_id_set[word] = id;
    color_group_index = color_group_index + 1
    if color_group_index > #colors then color_group_index = 1 end
end

local function highlight_current_word()
    --[[
    expand('<cword>')
    返回当前光标所在 word 的字符串
    --]]
    local word = vim.fn.expand('<cword>')
    --[[
    因为 matchadd() 是字符串匹配高亮，所以当一个 word 的子串是符合条件的，则会高亮这个子串
    例如，matchadd("Visula", 'vim') 会高亮所有字符串 vim，包括 nvim neovim，中的子串 vim 部分
    所以需要使用 vim 中的 pattern 来匹配，在前后分别加上 \< \>，作用类似于正则匹配中的 ^ &
    \<: 匹配单词起点: 下一个字符是单词的首字符。
    \>: 匹配单词终点: 前一个字符是单词的尾字符。
    \V: 使用 "\V" 会使得在它之后，只有反斜杠和终止字符 (通常是 / 或 ?) 有特殊的意义
    防止要高亮的字符串中含有一些别的用于 pattern 的字符串，导致出现预期外的结果
    类似的还有 "\M"，会使得其后的模式的解释方式就如同设定了 'nomagic' 选项一样。
    --]]
    local pattern  = "\\V\\<" .. word .. "\\>"
    highlight(word, pattern)
end

function highlight_string()
    local _, start_row, start_col, _ = unpack(vim.fn.getpos("'<"))
    local _, end_row, end_col, _ = unpack(vim.fn.getpos("'>"))
    if start_row ~= end_row then
        print("simple_hightlight_words.nvim : not support highlight multiple lines.")
        return
    end
    local str = ""
    if end_col == vim.v.maxcol then
        str = vim.api.nvim_buf_get_lines(0, start_row-1, start_row, true)[1]
    else
        str = vim.api.nvim_buf_get_text(0, start_row-1, start_col-1, end_row-1, end_col, {})[1]
    end
    local pattern  = "\\V" .. str
    highlight(str, pattern)
end

local function highlight_clear()
    for k, v in pairs(hightlight_id_set) do
        vim.fn.matchdelete(v)
        hightlight_id_set[k] = nil
    end
    color_group_index = 1
end

local M = {}

function M.setup(opts)
    vim.keymap.set('n', '<leader>hl', function() highlight_current_word() end, { noremap = true, silent = true })
    vim.keymap.set('n', '<leader>nohl', function() highlight_clear() end, { noremap = true, silent = true })
    vim.keymap.set('v', '<leader>hl', ":lua highlight_string()<CR>", { noremap = true, silent = true })
end

return M
