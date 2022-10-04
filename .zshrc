# p10k pre {{{
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
# }}}

# zinit install and load {{{
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    __zinit="zdharma-continuum/zinit"
    print -P "%F{12}▓▒ Installing Plugin Manager %F{13}${__zinit}%F{12}...%f"
    mkdir -p "$HOME/.zinit"
    git clone "https://github.com/${__zinit}.git" "$HOME/.zinit/bin" && \
        print -P "%F{12}▓▒ %F{14}Installation successful.%f%b" || \
        print -P "%F{12}▓▒ %F{09}The clone has failed.%f%b"
    unset __zinit
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
# }}}

# zinit plugins {{{
## Theme
zinit ice lucid depth"1"
zinit light romkatv/powerlevel10k

## Plugin
zinit wait lucid depth=1 light-mode for \
    atload"_zsh_autosuggest_start" zsh-users/zsh-autosuggestions \
    zsh-users/zsh-history-substring-search \
    jeffreytse/zsh-vi-mode

zinit ice wait"1" lucid depth=1 atinit"zicompinit; zicdreplay"
zinit light zdharma-continuum/fast-syntax-highlighting

## Completions
if [ -n "${HOMEBREW_PREFIX+x}" ]; then
    for __completion in $HOMEBREW_PREFIX/share/zsh/site-functions/*; do
        zinit ice as"completion" wait lucid
        zinit snippet $__completion
    done
    unset __completion
fi
if [ -n "$(ls --color=no $HOME/.local/share/zsh/site-functions)" ]; then
    for __completion in $HOME/.local/share/zsh/site-functions/*; do
        zinit ice as"completion" wait lucid
        zinit snippet $__completion
    done
    unset __completion
fi
# }}}

# zstyle {{{
zstyle ':completion:*' verbose yes
zstyle ':completion:*' menu yes select
zstyle ':completion:*' ignore-case yes
zstyle ':completion:*' list-colors ''
zstyle ':completion::complete:*' use-cache 1
# }}}

# keymaps {{{
bindkey -v
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
# }}}

# aliases {{{
# ls
## normal ls
alias ls='command ls --color'
## ls all =======================================
alias la='command ls -Alh --color'
alias lar='command ls -Alhr --color'
alias lat='command ls -Alht --color'
alias latr='command ls -Alhtr --color'
alias laz='command ls -AlhS --color'
alias lazr='command ls -AlhSr --color'
## ls all files ---------------------------------
alias laf='command ls -dlh --color .*(^/) *(^/)'
alias lafr='command ls -dlhr --color .*(^/) *(^/)'
alias laft='command ls -dlht --color .*(^/) *(^/)'
alias laftr='command ls -dlhtr --color .*(^/) *(^/)'
alias lafz='command ls -dlhS --color .*(^/) *(^/)'
alias lafzr='command ls -dlhSr --color .*(^/) *(^/)'
## ls all dirs ----------------------------------
alias lad='command ls -dlh --color .*(^/) *(^/)'
alias ladr='command ls -dlhr --color .*(^/) *(^/)'
alias ladt='command ls -dlht --color .*(^/) *(^/)'
alias ladr='command ls -dlhtr --color .*(^/) *(^/)'
alias ladz='command ls -dlhS --color .*(^/) *(^/)'
alias ladzr='command ls -dlhSr --color .*(^/) *(^/)'
## ls no hiddens ================================
alias l='command ls -lh --color'
alias ll='command ls -lh --color'
alias llr='command ls -lhr --color'
alias llt='command ls -lht --color'
alias lltr='command ls -lhtr --color'
alias llz='command ls -lhS --color'
alias llzr='command ls -lhSr --color'
## ls no hidden files ---------------------------
alias llf='command ls -dlh --color *(^/)'
alias llfr='command ls -dlhr --color *(^/)'
alias llft='command ls -dlht --color *(^/)'
alias llftr='command ls -dlhtr --color *(^/)'
alias llfz='command ls -dlhS --color *(^/)'
alias llfzr='command ls -dlhSr --color *(^/)'
## ls no hidden dirs ----------------------------
alias lld='command ls -dlh --color *(/)'
alias lldr='command ls -dlhr --color *(/)'
alias lldt='command ls -dlht --color *(/)'
alias lldtr='command ls -dlhtr --color *(/)'
alias lldz='command ls -dlhS --color *(/)'
alias lldzr='command ls -dlhSr --color *(/)'
## ls hiddens ===================================
alias lh='command ls -dlh --color .*'
alias lhr='command ls -dlhr --color .*'
alias lht='command ls -dlht --color .*'
alias lhtr='command ls -dlhtr --color .*'
alias lhz='command ls -dlhS --color .*'
alias lhzr='command ls -dlhSr --color .*'
## ls hidden files ------------------------------
alias lhf='command ls -dlh --color .*(^/)'
alias lhfr='command ls -dlhr --color .*(^/)'
alias lhft='command ls -dlht --color .*(^/)'
alias lhftr='command ls -dlhtr --color .*(^/)'
alias lhfz='command ls -dlhS --color .*(^/)'
alias lhfzr='command ls -dlhSr --color .*(^/)'
## ls hidden dirs --------------------------------
alias lhd='command ls -dlh --color .*(/)'
alias lhdr='command ls -dlhr --color .*(/)'
alias lhdt='command ls -dlht --color .*(/)'
alias lhdtr='command ls -dlhtr --color .*(/)'
alias lhdz='command ls -dlhS --color .*(/)'
alias lhdzr='command ls -dlhSr --color .*(/)'
# misc
alias ...='cd ../..'
alias cgrep='command grep --color'
alias rm='rm -i'
alias vi='vim'
if command -v nvim &> /dev/null; then
    alias vim='nvim'
    alias vimdiff='nvimdiff'
fi
alias yadm='yadm --yadm-repo $HOME/.git'
# set LD_LIBRARY_PATH for julia to avoid use wrong lib
if [ -n "$LD_LIBRARY_PATH" ]; then
    __JULIA_LIBRARY="$(dirname $(readlink -f $(which julia)))/../lib/julia"
    alias julia="LD_LIBRARY_PATH='$__JULIA_LIBRARY:$LD_LIBRARY_PATH' julia"
fi
sshr(){
    # use a random port from 30000 to 40000
    sshr_port=$((30000 + $RANDOM % 10000)) 
    echo "Use port $sshr_port for remote forward to localhost:22"
    ssh -t -R ${sshr_port}:localhost:22 $1 -o RemoteCommand="
        export SHELL=/home/%r/.local/bin/zsh \
               SSHR_PORT=$sshr_port \
               LC_HOST=$USER\@localhost LC_OS=$(uname -s) \
               TERM_PROGRAM=$TERM_PROGRAM;
        exec \$SHELL -l"
}
# }}}

# environment variables {{{
SAVEHIST=10000
HISTFILE=${HISTFILE-"$HOME/.zsh_history"}
unset LS_COLORS
export VISUAL=${VISUAL-${aliases[vim]-vim}}
export EDITOR=${EDITOR-"${aliases[vim]-vim} -e"}
export GIT_DIFF_TOOL=${GIT_DIFF_TOOL-${aliases[vimdiff]-vimdiff}}
export GIT_EDITOR=${GIT_EDITOR-$VISUAL}
export JULIA_EDITOR=${JULIA_EDITOR-$VISUAL}
export ESH_SHELL=${ESH_SHELL-"/bin/bash"}
# }}}

# conda initialize {{{
# !!! Conda must be installed at ~/Conda
__conda_dir="$HOME/Conda"
__conda_setup="$($__conda_dir/bin/conda shell.zsh hook 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$__conda_dir/etc/profile.d/conda.sh" ]; then
        . "$__conda_dir/etc/profile.d/conda.sh"
    else
        export PATH="$__conda_dir/bin:$PATH"
    fi
fi
unset __conda_dir
unset __conda_setup
# }}}

# iterm2 shell integration {{{
test -e "${HOME}/.iterm2_shell_integration.zsh" &&
    [ "$TERM_PROGRAM" = "iTerm.app" ] &&
    source "${HOME}/.iterm2_shell_integration.zsh"
# }}}

# p10k post {{{
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# }}}

# vim:tw=76:ts=4:sw=4:et:fdm=marker
