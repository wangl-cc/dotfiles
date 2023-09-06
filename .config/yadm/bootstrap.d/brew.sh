echo -e "\n\033[1;35mSetting up homebrew...\033[0m"

default_git_remote="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
env_git_remote="${HOMEBREW_BREW_GIT_REMOTE:-"$default_git_remote"}" # useful for reset to default
homebrew_mirror=$(dirname "$env_git_remote")

brew="$(brew --repo)"
brew_url=$(git -C "$brew" remote get-url origin)
brew_mirror="$homebrew_mirror/brew.git"
if [[ "$brew_url" != "$brew_mirror" ]]; then
  export HOMEBREW_BREW_GIT_REMOTE="$brew_mirror"
fi

for tap in cask{-fonts,-drivers,-versions} command-not-found services; do
  repo=$(brew --repo "homebrew/$tap")
  if [ -d "$repo" ]; then
    url=$(git -C "$repo" remote get-url origin)
    mirror="$homebrew_mirror/homebrew-$tap.git"
    if [[ "$url" != "$mirror" ]]; then
      brew tap --custom-remote --force-auto-update "homebrew/$tap" \
        "$homebrew_mirror/homebrew-$tap.git"
    fi
  fi
done

brew update
