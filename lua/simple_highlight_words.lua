local colors = { "#8CCBEA", "#A4E57E", "#FFDB72", "#FF7272", "#FFB3FF", "#9999FF" }
local highlight_prefix = "simple_hightlight_"
for index, color in ipairs(colors) do
    --[[
    nvim_set_hl({ns_id}, {name}, {*val})
    name: 高亮组名
    val:
        background: 设置用于高亮字符串的背景方框的颜色
        foreground: 设置高亮后的字符串字体的颜色
    --]]
    vim.api.nvim_set_hl(0, highlight_prefix .. index, { background = color })
end

local hightlight_id_set = {}
local color_group_index = 1

local function highlight_current_word()
    --[[
    expand('<cword>')
    返回当前光标所在 word 的字符串
    --]]
    local word = vim.fn.expand('<cword>')
    if hightlight_id_set[word] == nil then
        --[[
        matchadd({group}, {pattern},...)
        将符合 pattern 的字符串加入 group 高亮组
        因为是字符串匹配高亮，所以当一个 word 的子串是符合条件的，则会高亮这个子串
        例如，matchadd("Visula", 'vim') 会高亮所有字符串 vim，包括 nvim neovim，中的子串 vim 部分
        所以需要使用 vim 中的 pattern 来匹配，在前后分别加上 \< \>，作用类似于正则匹配中的 ^ &
        \<	匹配单词起点: 下一个字符是单词的首字符。
        \>	匹配单词终点: 前一个字符是单词的尾字符。
        --]]
        local pattern  = "\\<" .. word .. "\\>"
        -- local pattern  = string.format('\\V\\<%s\\>', word)
        local id = vim.fn.matchadd(highlight_prefix .. color_group_index, pattern)
        hightlight_id_set[word] = id;
        color_group_index = color_group_index + 1
        if color_group_index > 6 then color_group_index = 1 end
        return
    end
    vim.fn.matchdelete(hightlight_id_set[word])
    hightlight_id_set[word] = nil;
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
end

return M
