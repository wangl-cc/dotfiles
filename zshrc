# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git gitignore vi-mode history-substring-search)

source $ZSH/oh-my-zsh.sh

# bindkey
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# aliases
alias ...='../..'
alias ls='ls --color=auto'
alias da='du -sch'
alias dir='command ls -lSrah'
alias egrep='egrep --color=auto'
alias grep='grep --color=auto'
alias keep='noglob keep'
alias l='command ls -l --color=auto'
alias la='command ls -la --color=auto'
alias lad='command ls -d .*(/)'
alias lh='command ls -hAl --color=auto'
alias ll='command ls -al --color=auto'
alias llog=journalctl
alias ls='command ls --color=auto'
alias lsa='command ls -a .*(.)'
alias lsbig='command ls -flh *(.OL[1,10])'
alias lsd='command ls -d *(/)'
alias lse='command ls -d *(/^F)'
alias lsl='command ls -l *(@)'
alias lsnew='command ls -rtlh *(D.om[1,10])'
alias lsnewdir='command ls -rthdl *(/om[1,10]) .*(D/om[1,10])'
alias lsold='command ls -rtlh *(D.Om[1,10])'
alias lsolddir='command ls -rthdl *(/Om[1,10]) .*(D/Om[1,10])'
alias lss='command ls -l *(s,S,t)'
alias lssmall='command ls -Srl *(.oL[1,10])'
alias lsw='command ls -ld *(R,W,X.^ND/)'
alias lsx='command ls -l *(*)'
alias rm='rm -ri'
alias vi='vim'
alias setproxy='export http_proxy="http://127.0.0.1:7890/";
                export https_proxy="http://127.0.0.1:7890/";
                export all_proxy="socks5://127.0.0.1:7891/"'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_dir="$HOME/.miniconda"
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
# <<< conda initialize <<<

# pip zsh completion start
function _pip_completion {
  local words cword
  read -Ac words
  read -cn cword
  reply=( $( COMP_WORDS="$words[*]" \
             COMP_CWORD=$(( cword-1 )) \
             PIP_AUTO_COMPLETE=1 $words[1] 2>/dev/null ))
}
compctl -K _pip_completion pip
# pip zsh completion end
