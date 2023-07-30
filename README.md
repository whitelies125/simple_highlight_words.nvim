# simple_highlight_words.nvim

用于高亮多个 word 的 neovim 插件。

# usage

在 normal 模式下，光标处于一个 word 上时，输入快捷键使用

循环使用高亮组，可无上限高亮单词

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