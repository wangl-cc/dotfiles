if !exists("g:python_command")
    let g:python_command = "python"
endif

if !exists("g:python_comment_symbol")
    let g:python_comment_symbol = '#'
endif

nnoremap <buffer> <leader>r :w<cr>:call run#QuickRun(g:python_command)<cr>
nnoremap <buffer> <leader>/ :call comment#Comment(g:python_comment_symbol)<cr>
