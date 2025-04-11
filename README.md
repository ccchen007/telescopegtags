# telescopegtags

fork from  https://github.com/ivechan/telescope-gtags.git

lazy setting
```

return {
  "ccchen007/telescopegtags",
  config = function()

      vim.keymap.set('n', '<leader>gr', function()
          require('telescope-gtags').showReference()
      end, { noremap = true, silent = true, desc = "Show GTAGS references" })

      vim.keymap.set('n', '<leader>gd', function()
          require('telescope-gtags').showDefinition()
      end, { silent = true, noremap = true, desc = 'find in gtags current word Definition' })

      vim.api.nvim_set_keymap('n', '<leader>lug', '<cmd>lua require("telescope-gtags").updateGtags()<CR>', { silent = true, noremap = true })
  end,

}

```

