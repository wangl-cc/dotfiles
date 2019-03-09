function! run#QuickRun(command)
    silent !clear
    execute "!" . a:command . " " . bufname("%")
endfunction
