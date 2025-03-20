# telescopegtags

fork from  https://github.com/ivechan/telescope-gtags.git


nnoremap <leader>m <cmd>lua require('telescope.builtin').oldfiles()<CR>
nnoremap <silent> <leader>gu :lua require('telescope-gtags').updateGtags()<CR>
nnoremap <leader>ld <cmd>lua require('telescope-gtags').showDefinition()<cr>
nnoremap <leader>li <cmd>lua require('telescope-gtags').showReference()<cr>
nnoremap <leader>lh <cmd>lua require('telescope-gtags').showdeclare()<cr>
