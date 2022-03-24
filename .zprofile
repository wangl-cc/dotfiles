# Fig pre block. Keep at the top of this file.
eval "$(fig init zsh pre)"

if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Fig post block. Keep at the bottom of this file.
eval "$(fig init zsh post)"
