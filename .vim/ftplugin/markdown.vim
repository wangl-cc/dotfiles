if !exists("g:viewer_command")
    let g:viewer_command = "google-chrome-stable --new-window"
endif

nnoremap <buffer> <leader>v :w<cr>:call run#QuickRun(g:viewer_command)<cr>
