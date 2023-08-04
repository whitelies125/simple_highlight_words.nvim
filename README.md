# simple_highlight_words.nvim

用于高亮多个 word 的 neovim 插件。

循环使用高亮组，可无上限高亮单词

# usage

### normal

高亮光标所在的或附近的一个 word

highlight a word on or near the cursor

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
    config = function(_, opts)
        require("simple_highlight_words").setup()
    end,
}
```

# reference

https://github.com/leisiji/interestingwords.nvim, very tidy and helpful for me.
