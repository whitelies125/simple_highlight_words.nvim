local M = {}

local Pattern_states = {}
local Color_group_index = 1
local Colors = {}
local Highlight_prefix = "simple_hightlight_"

local function escape_pattern_text(text)
    -- 在 Vim 的 \V 模式下，反斜杠仍有特殊含义，需要先转义。
    return text:gsub("\\", "\\\\")
end

local function add_pattern_all_windows(pattern, group)
    --[[
    matchadd({group}, {pattern}, ...)
    在各个 window 中为 pattern 添加“匹配高亮”，并记录每个 window 的 match id。
    --]]
    local ids = {}
    for _, win_id in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win_id) then
            vim.api.nvim_win_call(win_id, function()
                ids[win_id] = vim.fn.matchadd(group, pattern)
            end)
        end
    end
    Pattern_states[pattern] = { group = group, ids = ids }
end

local function remove_pattern_all_windows(pattern)
    --[[
    matchdelete({id} [, {win}])
    仅删除本插件创建的 match id，不影响其他插件/用户创建的匹配高亮。
    --]]
    local pattern_state = Pattern_states[pattern]
    if pattern_state == nil then
        return
    end

    for win_id, id in pairs(pattern_state.ids) do
        pcall(vim.fn.matchdelete, id, win_id)
    end

    Pattern_states[pattern] = nil
end

local function highlight(pattern)
    --[[
    切换某个 pattern 的高亮状态:
    - 不存在: 在所有 window 添加
    - 已存在: 在所有 window 删除
    --]]
    if Pattern_states[pattern] == nil then
        add_pattern_all_windows(pattern, Highlight_prefix .. Color_group_index)
        Color_group_index = Color_group_index % #Colors + 1
    else
        remove_pattern_all_windows(pattern)
    end
end

function M.highlight_clear()
    --[[
    只清理本插件维护的 pattern，不使用 clearmatches() 全量清空窗口高亮，
    避免误删其他插件/用户的匹配高亮。
    --]]
    local patterns = {}
    for pattern, _ in pairs(Pattern_states) do
        table.insert(patterns, pattern)
    end

    for _, pattern in ipairs(patterns) do
        remove_pattern_all_windows(pattern)
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
    local pattern = "\\V\\<" .. escape_pattern_text(word) .. "\\>"
    highlight(pattern)
end

local function exit_visual_mode()
    vim.api.nvim_input("<Esc>")
end

function M.highlight_string()
    local _, start_row, start_col, _ = unpack(vim.fn.getpos("v"))
    local end_row, end_col = unpack(vim.api.nvim_win_get_cursor(0));
    end_col = end_col + 1

    local mode = vim.api.nvim_get_mode().mode
    if mode == "V" then
        start_col = 1
        end_col = vim.v.maxcol
    end

    if start_row > end_row or (start_row == end_row and start_col > end_col) then
        start_row, end_row = end_row, start_row
        start_col, end_col = end_col, start_col
    end

    if start_row ~= end_row then
        vim.notify("simple_hightlight_words.nvim : not support highlight multiple lines.", vim.log.levels.WARN)
        exit_visual_mode();
        return
    end

    local str = ""
    if end_col == vim.v.maxcol then
        str = vim.api.nvim_buf_get_lines(0, start_row - 1, start_row, true)[1]
    else
        str = vim.api.nvim_buf_get_text(0, start_row - 1, start_col - 1, end_row - 1, end_col, {})[1]
    end

    local first_no_blank_index = str:find("%S")
    if first_no_blank_index ~= nil then
        str = str:sub(first_no_blank_index)
    end

    -- 防止在空行使用该函数
    if str == '' then 
        exit_visual_mode();
        return
    end
    local pattern = "\\V" .. escape_pattern_text(str)
    highlight(pattern)
    exit_visual_mode();
end

function M.setup(opts)
    opts = opts or {}
    Color_group_index = 1
    Pattern_states = {}

    local default_colors = { "#8CCBEA", "#A4E57E", "#FFDB72", "#FF7272", "#FFB3FF", "#9999FF", "#FA9425", "#C49791" }
    Colors = opts.colors or default_colors

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

    local augroup = vim.api.nvim_create_augroup("simple_highlight_words", { clear = true })
    vim.api.nvim_create_autocmd({ "WinNew" }, {
        group = augroup,
        callback = function(_)
            local new_win = vim.api.nvim_get_current_win()
            for pattern, pattern_state in pairs(Pattern_states) do
                vim.api.nvim_win_call(new_win, function()
                    pattern_state.ids[new_win] = vim.fn.matchadd(pattern_state.group, pattern)
                end)
            end
        end,
    })

    vim.api.nvim_create_autocmd({ "WinClosed" }, {
        group = augroup,
        callback = function(ev)
            local win_id = tonumber(ev.match)
            if win_id == nil then return end
            for _, pattern_state in pairs(Pattern_states) do
                pattern_state.ids[win_id] = nil
            end
        end,
    })
end

return M
