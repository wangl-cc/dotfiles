if !exists("b:python_command")
    let b:python_command = "python"
endif

if !exists("b:python_comment_symbol")
    let b:python_comment_symbol = '#'
endif

nnoremap <buffer> <leader>r :w<cr>:call run#QuickRun(b:python_command)<cr>
nnoremap <buffer> <leader>/ :call comment#Comment(b:python_comment_symbol)<cr>
