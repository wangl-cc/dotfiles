status is-interactive; or return

type -q zoxide; and zoxide init fish | source

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
