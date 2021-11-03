#### FIG ENV VARIABLES ####
# Please make sure this block is at the start of this file.
[ -s ~/.fig/shell/pre.sh ] && source ~/.fig/shell/pre.sh
#### END FIG ENV VARIABLES ####

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# mirrors used by zinit
GITHUBURL='gitee.com'
zdharma='wangl-cc'
zsh_users="wangl-cc"

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone "https://$GITHUBURL/$zdharma/zinit" "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk

### Theme
zinit ice lucid depth"1" from"$GITHUBURL"
zinit light romkatv/powerlevel10k # there is an official mirror on gitee

### Plugin
zinit wait lucid depth=1 light-mode from"$GITHUBURL" for \
    atload"_zsh_autosuggest_start" $zsh_users/zsh-autosuggestions \
    $zsh_users/zsh-history-substring-search

zinit ice wait"1" lucid depth=1 atinit"zicompinit; zicdreplay" from"$GITHUBURL"
zinit light $zdharma/fast-syntax-highlighting

### Completion

zinit as"completion" wait lucid is-snippet for \
    .yadm-project/completion/zsh/_yadm \

if command -v brew &> /dev/null; then
    zinit ice as"completion" wait lucid
    zinit snippet $(brew --prefix)/share/zsh/site-functions/_brew
fi

### zstyle
zstyle ':completion:*' verbose yes
zstyle ':completion:*' menu yes select
zstyle ':completion::complete:*' use-cache 1
zstyle ":conda_zsh_completion:*" use-groups true

### Keymaps
bindkey -v
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# aliases
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

# environment variables
SAVEHIST=10000
if [ -z ${HISTFILE+x} ]; then
    HISTFILE=$HOME/.zsh_history
fi

if [ -z ${JULIA_EDITOR+x} ]; then
    export JULIA_EDITOR="vim"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# >>> conda initialize >>>
# !!! Conda must be installed at ~/Applications/Conda
__conda_dir="$HOME/Applications/Conda"
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

#### FIG ENV VARIABLES ####
# Please make sure this block is at the end of this file.
[ -s ~/.fig/fig.sh ] && source ~/.fig/fig.sh
#### END FIG ENV VARIABLES ####
