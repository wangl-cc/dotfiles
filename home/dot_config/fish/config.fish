# Force some programs use XDG_CONFIG_HOME
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx WAKATIME_HOME $XDG_CONFIG_HOME/wakatime
set -gx GNUPGHOME $XDG_CONFIG_HOME/gnupg

status is-interactive; or return

set -gx COPYFILE_DISABLE 1 # Prevent tar from creating ._ files on macOS
abbr --add -- tx tar -xf
abbr --add -- tc tar -cf

set -gx LS_COLORS "di=1;34:ex=1;32:fi=39:pi=33:so=1;31:bd=1;33:cd=1;33:ln=36:or=31"
if type -q eza
    alias eza 'eza --icons auto --group-directories-first'
    abbr --add -- l eza
    abbr --add -- ll eza -l
    abbr --add -- la eza -Al
    abbr --add -- lt eza --tree
else
    abbr --add l -- ls --color
    abbr --add ll -- ls --color -lh
    abbr --add la -- ls --color -Alh
end

function expand_dot
    string repeat -n (math (string length -- $argv[1]) - 1) ../
end
abbr --add --function expand_dot --regex '^\.\.+$' -- dots
type -q zoxide; and zoxide init fish | source

abbr --add -- g git
abbr --add -- ga git add
abbr --add -- gaa git add --all
abbr --add -- gb git branch
abbr --add -- gba git branch -a
abbr --add -- gbd git branch -d
abbr --add -- gbl git branch -l
abbr --add -- gc git commit
abbr --add -- gcl git clone
abbr --add -- gco git checkout
abbr --add -- gcb git checkout -b
abbr --add -- gcm git checkout main
abbr --add -- gci git check-ignore -v
abbr --add -- gd git diff
abbr --add -- gds git diff --staged
abbr --add -- gl git log
abbr --add -- gp git push
abbr --add -- gpt git push --tags
abbr --add -- gpl git pull --ff-only
abbr --add -- gr git remote
abbr --add -- grv git remote -v
abbr --add -- gra git remote add
abbr --add -- gs git status
abbr --add -- gsu git status -u
abbr --add -- gt git tag
type -q lazygit; and abbr --add -- gg lazygit

if type -q brew
    abbr --add -- b brew
    abbr --add -- bc brew cleanup
    abbr --add -- bca brew cleanup --prune=all
    abbr --add -- bi brew install
    abbr --add -- bl brew leaves
    abbr --add -- bls brew list
    abbr --add -- blc brew list --cask
    abbr --add -- br brew remove
    abbr --add -- bs brew search
    abbr --add -- bu brew upgrade
end

if type -q julia
    abbr --add -- jl julia
    abbr --add -- jp julia --project
end

if type -q cargo
    abbr --add -- c cargo
    abbr --add -- ca cargo add
    abbr --add -- crm cargo remove
    abbr --add -- cr cargo run
    abbr --add -- cb cargo build
    abbr --add -- ccl cargo clean
    abbr --add -- cck cargo check
    abbr --add -- cf cargo +nightly fmt
    if type -q cargo-nextest
        abbr --add -- ct cargo nextest run
    else
        abbr --add -- ct cargo test
    end
    abbr --add -- ci cargo install
    abbr --add -- cil cargo install --locked
    abbr --add -- cl cargo install --list
    abbr --add -- clp cargo clippy --all-targets -- -D warnings
    abbr --add -- cu cargo uninstall
    abbr --add -- cup cargo update
end

if type -q chezmoi
    abbr --add -- cz chezmoi
    abbr --add -- cza chezmoi add
end

if type -q nvim
    # nv is a wrapper for nvim which use nvr inside neovim
    # to open files in the same instance
    abbr --add -- vi nv
    abbr --add -- vim nv
    abbr --add -- nvim nv
    set -q VISUAL; or set -gx VISUAL nv
else if type -q vim
    abbr --add vi -- vim
    set -q VISUAL; or set -gx VISUAL vim
end

if type -q fd
    alias fd "fd --hidden --follow"
    set -gx FZF_DEFAULT_COMMAND "fd --strip-cwd-prefix"
    set -gx FZF_CTRL_T_COMMAND "fd --type f --strip-cwd-prefix"
    set -gx FZF_ALT_C_COMMAND "fd --type d --strip-cwd-prefix"
end

if type -q fzf
    set -gx FZF_DEFAULT_OPTS "--height=40% --layout=reverse --border --prompt='> '"
    fzf --fish | source
end

type -q atuin; and atuin init fish --disable-up-arrow | source

type -q fastfetch; and abbr --add -- ff fastfetch

type -q starship; and starship init fish | source

set -g fish_key_bindings fish_vi_key_bindings
function fish_user_key_bindings
    fish_default_key_bindings -M insert # set default key bindings for insert mode
    # then execute the vi-bindings so they take precedence when there's a conflict.
    fish_vi_key_bindings --no-erase insert
end
set -g fish_cursor_default block
set -g fish_cursor_insert line
set -g fish_cursor_replace underscore
set -g fish_cursor_replace_one underscore
