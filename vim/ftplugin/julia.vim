if !exists("g:julia_command")
    let g:julia_command = "julia --color=yes"
endif

if !exists("g:julia_comment_symbol")
    let g:julia_comment_symbol = '#'
endif

nnoremap <buffer> <leader>r :w<cr>:call julia#JuliaRun(g:julia_command)<cr>
nnoremap <buffer> <leader>/ :call comment#Comment(g:julia_comment_symbol)<cr>
