local M = {}

local function highlight(pattern)
    --[[
    getmatched([{win}])
    返回之前 matchadd() 和 :match 命令为当前窗口定义的所有“匹配高亮”组成的列表 List
    可给出 win 返回指定窗口的内容
    --]]
    local cur_matches = vim.fn.getmatches()
    local has_exsited = false
    local id = nil
    for _, item in pairs(cur_matches) do
        if item['pattern'] == pattern then
            has_exsited = true
            id = item['id']
            break;
        end
    end

    if has_exsited == false then
        --[[
        matchadd({group}, {pattern},...)
        将符合 pattern 的字符串加入 group 高亮组
        并返回一个 id，该 id 可用于 matchdelete(id) 删除高亮组 group 对该 pattern 的匹配

        为了方便，在这个文件中，我个人就把这种方式的高亮称为“匹配高亮”吧
        --]]
        vim.fn.matchadd(Highlight_prefix .. Color_group_index, pattern)
        Color_group_index = Color_group_index % #Colors + 1
    else
        vim.fn.matchdelete(id)
    end

    -- 同步当前 window 的“匹配高亮”到到所有 window
    local cur_win = vim.api.nvim_get_current_win()
    Matches_config = vim.fn.getmatches()
    local wins = vim.api.nvim_list_wins()
    for _, win_id in pairs(wins) do
        if win_id ~= cur_win then
            --[[
            setmatches({list} [, {win}])
            原有的所有匹配高亮都被清除
            按 {list} 对当前窗口设置“匹配高亮”
            如果成功，返回 0，否则返回 -1
            可给出 {win} 对指定窗口进行设置
            --]]
            vim.fn.setmatches(Matches_config, win_id)
        end
    end
end

function M.highlight_clear()
    local wins = vim.api.nvim_list_wins()
    for _, win_id in pairs(wins) do
        --[[
        clearmatches([{win}])
        清除之前 matchadd() 和 :match 命令为当前窗口定义的“匹配高亮”
        可给出 {win} 清除指定窗口的“匹配高亮”
        --]]
        vim.fn.clearmatches(win_id)
    end
    vim.cmd(":nohl")
end

function M.highlight_word()
    --[[
    expand('<cword>')
    返回当前光标所在 word 的字符串
    --]]
    local word = vim.fn.expand('<cword>')
    -- 防止在空行使用该函数
    if word == '' then return end
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
    local pattern = "\\V\\<" .. word .. "\\>"
    highlight(pattern)
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

    local first_no_blank_index = str:find("%S")
    if first_no_blank_index ~= nil then
        str = str:sub(first_no_blank_index)
    end
    -- 防止在空行使用该函数
    if str == '' then return end
    local pattern = "\\V" .. str
    highlight(pattern)
end

function M.setup(opts)
    Color_group_index = 1
    Matches_config = {}

    local default_colors = { "#8CCBEA", "#A4E57E", "#FFDB72", "#FF7272", "#FFB3FF", "#9999FF", "#FA9425", "#C49791" }
    --[[
    lua 中, false 和 nil 为假，其他值都为真
    not, 总是返回 true 或 false;
    and, 当第一个值为 false 或 nil 时，则返回第一个值，否则返回第二个值
    or, 当第一个值不为 false 或 nil 时，则返回第一个值，发展返回第二个值
    and 和 or 都使用短路求值，仅在必要时才求解第二个值
    --]]
    Colors = opts.Colors or default_colors

    Highlight_prefix = "simple_hightlight_"
    for index, color in ipairs(Colors) do
        --[[
        nvim_set_hl({ns_id}, {name}, {*val})
        name: 高亮组名
        val:
            background: 设置用于高亮字符串的背景方框的颜色
            foreground: 设置高亮后的字符串字体的颜色，这里设为黑色，避免 background 色与字体原本颜色相近导致看不清
        --]]
        vim.api.nvim_set_hl(0, Highlight_prefix .. index, { background = color, foreground = "Black" })
    end

    vim.api.nvim_create_autocmd({ "WinNew" }, {
        callback = function(ev)
            -- 新建 window 前，同步“匹配高亮”到新建的 window
            local cur_win = vim.api.nvim_get_current_win()
            vim.fn.setmatches(Matches_config, cur_win)
        end
    })
end

return M
