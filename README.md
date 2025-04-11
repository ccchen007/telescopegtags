# telescopegtags

fork from  https://github.com/ivechan/telescope-gtags.git

lazy setting
```

return {
  "ccchen007/telescopegtags",
  config = function()

      vim.keymap.set('n', '<leader>gr', function()
          require('telescope-gtags').showReference()
      end, { noremap = true, silent = true, desc = "Show GTAGS references of current word" })

      vim.keymap.set('n', '<leader>gd', function()
          require('telescope-gtags').showDefinition()
      end, { silent = true, noremap = true, desc = 'Show GTAGS definition of current word' })

      vim.api.nvim_set_keymap('n', '<leader>lug', '<cmd>lua require("telescope-gtags").updateGtags()<CR>', { silent = true, noremap = true })
  end,

}

```

It's better to use "git ls-files | gtags --incremental --file -" to generate glbal tags.
