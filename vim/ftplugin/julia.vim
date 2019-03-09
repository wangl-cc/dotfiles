if !exists("b:julia_command")
    let b:julia_command = "julia --color=yes"
endif

if !exists("b:julia_comment_symbol")
    let b:julia_comment_symbol = '#'
endif

nnoremap <buffer> <leader>r :w<cr>:call run#QuickRun(b:julia_command)<cr>
nnoremap <buffer> <leader>/ :call comment#Comment(b:julia_comment_symbol)<cr>
