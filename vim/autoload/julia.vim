function! julia#JuliaRun(julia_command)
    silent !clear
    execute "!" . a:julia_command . " " . bufname("%")
endfunction
