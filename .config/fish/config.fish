not status is-interactive; and return

# tar {{{
abbr --add tx tar -xf # extract
abbr --add tc tar -cf # create
# set COPYFILE_DISABLE=1 to prevent tar from creating ._ files on macOS
set -gx COPYFILE_DISABLE 1
# }}}

# rm {{{
abbr --add rm rm -i
abbr --add rf rm -f
abbr --add rr rm -ri
# }}}

# ls {{{
if type -q lsd
    abbr --add l lsd
    abbr --add ls lsd
    abbr --add ll lsd -l
    abbr --add la lsd -Al
    abbr --add tree lsd --tree
else
    abbr --add l ls --color
    abbr --add ll ls --color -lh
    abbr --add la ls --color -Alh
end
# }}}

# cd {{{
abbr --add .. cd ..
abbr --add ... cd ../..
abbr --add .... cd ../../..

type -q zoxide; and zoxide init fish | source
# }}}

# git {{{
abbr --add g git
abbr --add ga git add
abbr --add gaa git add --all
abbr --add gb git branch
abbr --add gba git branch -a
abbr --add gbd git branch -d
abbr --add gbl git branch -l
abbr --add gc git commit
abbr --add gcl git clone
abbr --add gco git checkout
abbr --add gcb git checkout -b
abbr --add gcm git checkout main
abbr --add gci git check-ignore -v
abbr --add gd git diff
abbr --add gds git diff --staged
abbr --add gl git log
abbr --add gp git push
abbr --add gpt git push --tags
abbr --add gpl git pull --ff-only
abbr --add gr git remote
abbr --add grv git remote -v
abbr --add gra git remote add
abbr --add gs git status
abbr --add gsu git status -u
abbr --add gt git tag
if type -q lazygit
    abbr --add gg lazygit
end
# git }}}

if type -q brew # {{{
    abbr --add b brew
    abbr --add bc brew cleanup
    abbr --add bca brew cleanup --prune=all
    abbr --add bi brew install
    abbr --add bl brew leaves
    abbr --add bls brew list
    abbr --add blc brew list --cask
    abbr --add br brew remove
    abbr --add bs brew search
    abbr --add bu brew upgrade
end
# }}}

if type -q yadm # {{{
    abbr --add y yadm
    abbr --add ya yadm alt
    abbr --add yb yadm bootstrap
    abbr --add yd yadm decrypt
    abbr --add ye yadm encrypt
    abbr --add yp yadm perms
    abbr --add yg yadm git-crypt
    abbr --add yt yadm transcrypt
end # }}}

if type -q julia # {{{
    abbr --add jl julia
    abbr --add jp julia --project
end # }}}

if type -q cargo # {{{
    abbr --add c cargo
    abbr --add ca cargo add
    abbr --add crm cargo remove
    abbr --add cr cargo run
    abbr --add cb cargo build
    abbr --add ccl cargo clean
    abbr --add cck cargo check
    abbr --add cf cargo fmt
    if type -q cargo-nextest
        abbr --add ct cargo nextest run
    else
        abbr --add ct cargo test
    end
    abbr --add ci cargo install
    abbr --add cil cargo install --locked
    abbr --add cl cargo install --list
    abbr --add clp cargo clippy --all-targets -- -D warnings
    abbr --add cu cargo uninstall
    abbr --add cup cargo update
end # }}}

if type -q nvim # {{{
    # nv is a wrapper for nvim
    abbr --add vi nv
    abbr --add vim nv
    abbr --add nvim nv
    set -gx VISUAL nv
else
    abbr --add vi vim
    set -gx VISUAL vim
end # }}}

if type -q fzf # {{{
    if type -q fd
        set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
    end
    set -gx FZF_DEFAULT_OPTS '--color=16'
end # }}}

if type -q fastfetch # {{{
    abbr --add ff fastfetch
    function fish_greeting
        fastfetch
    end
end # }}}

# prompt {{{
type -q starship; and starship init fish | source
# }}}

# misc {{{
set -gx ESH_SHELL /bin/bash
set -gx WAKATIME_HOME $HOME/.config/wakatime
set -gx BOB_CONFIG $HOME/.config/bob/config.json
set -gx MAA_LOG info
# }}}

# vi mode {{{
set -g fish_key_bindings fish_vi_key_bindings
function fish_user_key_bindings
    fish_default_key_bindings -M insert # set default key bindings for insert mode
    # then execute the vi-bindings so they take precedence when there's a conflict.
    fish_vi_key_bindings --no-erase insert
end
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace underscore
set fish_cursor_replace_one underscore
# }}}

# vim:foldmethod=marker
