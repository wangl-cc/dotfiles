function! juliacomplete#CompleteServer(findstart, base)
    if a:findstart
        call JLFindStart()
        return g:start
    else
        call JLComGet(a:base)
        return g:comp
endfunction

