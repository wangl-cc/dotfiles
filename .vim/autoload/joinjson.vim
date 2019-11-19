function! s:Read(file)
    if filereadable(a:file)
        let lines = readfile(a:file)
        let str = join(lines)
        return json_decode(str)
    else
        return {}
    endif
endfunction

function! s:Join(default, addition)
    for [key, val] in items(a:addition)
        let a:default[key] = val
    endfor
    return a:default
endfunction

let s:coc_settings_file_default = $HOME . "/.vim/coc-settings-default.json"
let s:coc_settings_file_user = $HOME . "/.vim/coc-settings-user.json"
let s:coc_settings_file_out = $HOME . "/.vim/coc-settings.json"

function! joinjson#Update()
    let default = s:Read(s:coc_settings_file_default)
    let user = s:Read(s:coc_settings_file_user)
    let out = s:Join(default, user)
    let out_str = json_encode(out)
    call writefile([out_str], s:coc_settings_file_out)
endfunction
