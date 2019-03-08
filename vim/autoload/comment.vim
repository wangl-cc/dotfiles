function! comment#Comment(comment_symbol)
    let l:line = getline('.')
    if l:line[0] == a:comment_symbol
        if l:line[1] == ' '
            execute ":s/^" . a:comment_symbol ."\\ //"
        else
            execute ":s/^" . a:comment_symbol ."//"
        endif
    else
        execute ":s/^/" . a:comment_symbol . "\\ /"
    endif
endfunction
