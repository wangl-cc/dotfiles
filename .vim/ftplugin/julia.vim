if !exists("g:julia_command")
    let julia_command = "julia"
endif

if !exists("g:julia_comment_symbol")
    let julia_comment_symbol = '#'
endif

nnoremap <buffer> <leader>r :w<cr>:call run#QuickRun(julia_command)<cr>
nnoremap <buffer> <leader>/ :call comment#Comment(julia_comment_symbol)<cr>
nnoremap <buffer> <leader>d :call juliadocstring#JuliaDocstring()<cr>
nnoremap <buffer> <leader>j :vsplit term://julia<cr>

call JLComInit()
setlocal completefunc=juliacomplete#CompleteServer

