# Fig pre block. Keep at the top of this file.
if command -v brew &> /dev/null; then
    eval "$(fig init zsh pre)"
fi

if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Fig post block. Keep at the bottom of this file.
if command -v fig &> /dev/null; then
    eval "$(fig init zsh post)"
fi
