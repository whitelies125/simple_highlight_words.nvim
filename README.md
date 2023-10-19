# simple_highlight_words.nvim

用于高亮 word 或选中字符串的 neovim 插件。

neovim plugin for highlighting word or selected string.

循环使用高亮组(可自定义)。

using highlight group(can be customized) cyclely.

# usage

### normal

高亮一个 word

highlight a word

![84](https://github.com/whitelies125/simple_highlight_words.nvim/assets/47108287/dd84057a-1ec0-4772-94fc-ec75ecabb4da)


### visual

高亮所选字符串

highlight the selected string

![85](https://github.com/whitelies125/simple_highlight_words.nvim/assets/47108287/78b8861a-f1a8-4371-a1fc-28d656176946)


# install

use lazy.nvim :

```
{
    "whitelies125/simple_highlight_words.nvim",
    -- 可自定义高亮组颜色
    -- you can customize your highlight group colors
    opts = { colors = { "#8CCBEA", "#A4E57E", "#FFDB72", "#FF7272",
                        "#FFB3FF", "#9999FF", "#FA9425", "#C49791" }
    },
    config = function(_, opts)
        local hl = require("simple_highlight_words")
        hl.setup(opts)
        local map_opt = { noremap = true, silent = true }
        -- 高亮 word
        -- highlight word
        vim.keymap.set('n', '<leader>hl', hl.highlight_word, map_opt)
        -- 取消所有高亮
        -- cancel all highlight
        vim.keymap.set('n', '<leader>nohl', hl.highlight_clear, map_opt)
        -- 高亮 visual 模式下选中的字符串
        -- highlight the selected string in visual mode
        vim.keymap.set('v', '<leader>hl', ":lua highlight_string()<CR>", map_opt)
    end,
}
```

# reference

https://github.com/leisiji/interestingwords.nvim, very tidy and helpful for me.
