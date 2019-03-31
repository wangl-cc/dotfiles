if !exists("g:julia_comment_symbol")
    let julia_comment_symbol = '#'
endif

nnoremap <buffer> <leader>l :call JLRunLine()<cr>
nnoremap <buffer> <leader>b :call JLRunBlock()<cr>
nnoremap <buffer> <leader>/ :call comment#Comment(julia_comment_symbol)<cr>
nnoremap <buffer> <leader>d :call juliadocstring#JuliaDocstring()<cr>

" autoclose
augroup JuliaAutoClose
    autocmd!
    autocmd bufenter * if (winnr("$") == 1 && bufname("$") =~ "julia") | q | endif
augroup END
