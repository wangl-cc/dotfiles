let s:juliakws=["abstract type", "baremodule", "begin", "do", "for", "function", "if", "let", "macro", "module", "quote", "struct", "try", "while"]

function! juliadocstring#FindCodeBlock()
    let n = line('.')
    let max = line('$')
    let c = 0
    while n <= max
        let line = getline(n)
        for kw in s:juliakws
            if stridx(line, kw) != -1
                let c += 1
            endif
        endfor
        if stridx(line, "end") != -1
            let c -= 1
        endif
        if c
            let n += 1
        else
            return n
        endif
    endwhile
    echo "[Warring] Cannot find the end of code block."
    return max
endfunction

let s:autoload_path = fnamemodify("~/.vim/autoload/", ":p")

if filereadable(s:autoload_path . "builddir/parse")
    let s:parse_exe = s:autoload_path . "builddir/parse"
else
    let s:parse_exe = s:autoload_path . "parse_exec.jl"
end

function! juliadocstring#JuliaDocstring()
    let line = getline(".")
    if strridx(line, "=") || stridx(line, "function") != -1 || stridx(line, "macro") != -1 || stridx(line, "struct") != -1 || stridx(line, "abstract type") != -1
        let s = line(".")
        let e = juliadocstring#FindCodeBlock()
        let codestring = join(getline(s, e), "\n")
        echo codestring
        let docstring = system(s:parse_exe . " -p '" . codestring . "'")
        call append(line(".")-1, split(docstring, "\n"))
    else
        echo "[Error] Cannot find target codes"
    endif
endfunction
