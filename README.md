# simple_highlight_words.nvim

用于高亮多个 word 的 neovim 插件。

循环使用高亮组，可无上限高亮单词

# usage

### normal

高亮光标所在的或附近的一个 word

### visual

高亮所选字符串

# install

使用 lazy.nvim :

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
