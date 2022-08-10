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
    jirutka         wangl-cc
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

# misc install {{{
__RC_PREFIX="$HOME/.local"
__RC_BINPATH="$__RC_PREFIX/bin"
__RC_MANPATH="$__RC_PREFIX/share/man"
__RC_COMPPATH="$__RC_PREFIX/share/zsh/site-functions"
if ! [ -d $__RC_COMPPATH ]; then
    mkdir -p $__RC_COMPPATH
fi
__RC_CACHEPATH="$TMPDIR/zshrc_download_cache"
if ! [ -d $__RC_CACHEPATH ]; then
    mktemp -d zshrc_download_cache
fi
__rc_install() {
    url="$1"
    dest="$2"
    mod="$3"
    name=$(basename $url)
    print -P "Installing %F{33}$name%F{34}%f:"
    print -P "URL: %F{33}$url%f"
    print -P "Destination: %F{33}$dest/$name%f"
    print -P "Mode: %F{33}$mod%f"
    curl -sSLo "$__RC_CACHEPATH/$name" "$url" && \
        install -m $mod "$__RC_CACHEPATH/$name" "$dest" && \
        print -P "Installation successful.%b" || \
        print -P "Installation failed.%b"
}
__rc_install_bin() { __rc_install $1 $__RC_BINPATH 755 }
__rc_install_comp() { __rc_install $1 $__RC_COMPPATH 644 }
__rc_install_man() {
    __rc_manpath="__RC_MANPATH/man${1##*.}"
    if ! [ -d $__rc_manpath ]; then
        mkdir -p $__rc_manpath
    fi
    __rc_install $1 $__rc_manpath 644
}
# install yadm
if test ! $(command -v yadm); then
    __RC_YADM_TAG="3.2.1"
    read -q "__RC_YADM_INSTALL?Install yadm? [y/n]"
    if [ $__RC_YADM_INSTALL = "y" ]; then
        __rc_install_bin "$(__github_url_raw TheLocehiliosan yadm)/$__RC_YADM_TAG/yadm"
        __rc_install_comp "$(__github_url_raw TheLocehiliosan yadm)/$__RC_YADM_TAG/completion/zsh/_yadm"
        __rc_install_man "$(__github_url_raw TheLocehiliosan yadm)/$__RC_YADM_TAG/yadm.1"
    else
        echo "yadm not installed."
    fi
fi
# install esh
if test ! $(command -v esh); then
    __RC_ESH_TAG="v0.3.2"
    read -q "__RC_ESH_INSTALL?Install esh? [y/n]"
    if [ $__RC_ESH_INSTALL = "y" ]; then
        __rc_install_bin "$(__github_url_raw jirutka esh)/$__RC_ESH_TAG/esh"
    else
        echo "esh not installed."
    fi
fi
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
if [ -n "${HOMEBREW_PREFIX+x}" ]; then
    for completion in $HOMEBREW_PREFIX/share/zsh/site-functions/*; do
        zinit ice as"completion" wait lucid
        zinit snippet $completion
    done
fi
for completion in $__RC_COMPPATH/*; do
    zinit ice as"completion" wait lucid
    zinit snippet $completion
done
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
alias lr='command ls -lhr --color'
alias lt='command ls -lht --color'
alias ltr='command ls -lhtr --color'
alias lz='command ls -lhS --color'
alias lzr='command ls -lhSr --color'
## ls no hidden files ---------------------------
alias lf='command ls -dlh --color *(^/)'
alias lfr='command ls -dlhr --color *(^/)'
alias lft='command ls -dlht --color *(^/)'
alias lftr='command ls -dlhtr --color *(^/)'
alias lfz='command ls -dlhS --color *(^/)'
alias lfzr='command ls -dlhSr --color *(^/)'
## ls no hidden dirs ----------------------------
alias ld='command ls -dlh --color *(/)'
alias ldr='command ls -dlhr --color *(/)'
alias ldt='command ls -dlht --color *(/)'
alias ldtr='command ls -dlhtr --color *(/)'
alias ldz='command ls -dlhS --color *(/)'
alias ldzr='command ls -dlhSr --color *(/)'
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
# }}}

# environment variables {{{
SAVEHIST=10000
HISTFILE=${HISTFILE-"$HOME/.zsh_history"}
export VISUAL=${VISUAL-${aliases[vim]-vim}}
export EDITOR=${EDITOR-"${aliases[vim]-vim} -e"}
export GIT_DIFF_TOOL=${GIT_DIFF_TOOL-${aliases[vimdiff]-vimdiff}}
export GIT_EDITOR=${GIT_EDITOR-$VISUAL}
export JULIA_EDITOR=${JULIA_EDITOR-$VISUAL}
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
