# p10k pre {{{
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
# }}}

# mirror url function {{{
## github domain name
__RC_GITHUB_DOMAIN="gitee.com"
## some mirrors is belong to me, thus those repo owners should be changed
typeset -A __RC_REPO_OWNERS=(
    zdharma         wangl-cc
    sobolevn        wangl-cc
    zsh-users       wangl-cc
    TheLocehiliosan wangl-cc
    romkatv         wangl-cc
)
## echo new owner for owner in REPO_OWNERS, otherwise echo the original owner
__repo_owner(){ echo ${__RC_REPO_OWNERS[$1]-$1} }
## echo github urls with given owner and repo
### Arguments: original owner, repo
__github_url_git(){ echo "https://$__RC_GITHUB_DOMAIN/$(__repo_owner $1)/$2.git" }
__github_url_raw(){ echo "https://$__RC_GITHUB_DOMAIN/$(__repo_owner $1)/$2/raw" }
# }}}

# zinit install and load {{{
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone $(__github_url_git zdharma zinit) "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
# }}}

# zinit plugins {{{
## Theme
zinit ice lucid depth"1" from"$__RC_GITHUB_DOMAIN"
zinit light $(__repo_owner romkatv)/powerlevel10k

## Plugin
# plugin use mirrors
zinit wait lucid depth=1 light-mode from"$__RC_GITHUB_DOMAIN" for \
    atload"_zsh_autosuggest_start" $(__repo_owner zsh-users)/zsh-autosuggestions \
    $(__repo_owner zsh-users)/zsh-history-substring-search \
    $(__repo_owner sobolevn)/wakatime-zsh-plugin

# plugin don't use mirrors
zinit wait lucid depth=1 light-mode for \
    jeffreytse/zsh-vi-mode

zinit ice wait"1" lucid depth=1 atinit"zicompinit; zicdreplay" from"$__RC_GITHUB_DOMAIN"
zinit light $(__repo_owner zdharma)/fast-syntax-highlighting

## Completions
zinit as"completion" wait lucid is-snippet for \
    "$(__github_url_raw TheLocehiliosan yadm)/master/completion/zsh/_yadm"

if [ -n "${HOMEBREW_PREFIX+x}" ]; then
    zinit ice as"completion" wait lucid
    zinit snippet $HOMEBREW_PREFIX/share/zsh/site-functions/_brew
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

# yadm installation {{{
__RC_YADM_PATH="$HOME/.local/bin/yadm"
install_yadm() {
    print -P "Downloading lastest %F{33}yadm%f to %F{33}$__RC_YADM_PATH%f..."
    curl -sSLo $__RC_YADM_PATH "$(__github_url_raw TheLocehiliosan yadm)/master/yadm" && \
        echo "Download succeed." || \
        echo "Download failed."
    chmod +x $__RC_YADM_PATH
}
if test ! $(command -v yadm); then
    if [[ ! -f $__RC_YADM_PATH ]]; then
        install_yadm
    else
        echo "yadm is found at $__RC_YADM_PATH, make sure it is in your PATH."
    fi
fi
# }}}

# aliases {{{
alias ...='../..'
alias ls='ls --color'
alias da='du -sch'
alias dir='command ls -lSrah'
alias egrep='egrep --color'
alias grep='grep --color'
alias keep='noglob keep'
alias l='command ls -l --color'
alias la='command ls -la --color'
alias lad='command ls -d .*(/)'
alias lh='command ls -hAl --color'
alias ll='command ls -al --color'
alias llog=journalctl
alias ls='command ls --color'
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
alias rm='rm -i'
alias vi='vim'
# }}}

# environment variables {{{
SAVEHIST=10000
if [ -z ${HISTFILE+x} ]; then
    HISTFILE=$HOME/.zsh_history
fi
if command -v nvim &> /dev/null; then
    alias vim='nvim'
    export GIT_DIFF_TOOL='nvimdiff'
else
    export GIT_DIFF_TOOL='vimdiff'
fi
if [ -z ${VISUAL+x} ]; then
    export VISUAL=${aliases[vim]-vim}
fi
if [ -z ${EDITOR+x} ]; then
    export EDITOR="${aliases[vim]-vim} -e"
fi
if [ -z ${JULIA_EDITOR+x} ]; then
    export JULIA_EDITOR=$VISUAL
fi
if [ -z ${GIT_EDITOR+x} ]; then
    export GIT_EDITOR=$VISUAL
fi
'@vim'() {vim $1 $2}
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
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
# }}}

# p10k post {{{
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# }}}

# vim:tw=76:ts=4:sw=4:et:fdm=marker
