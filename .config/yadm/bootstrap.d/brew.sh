set -e

echo -e "\n\033[1;35mSetting up homebrew...\033[0m"

export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
homebrew_tap_mirror="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew"

echo -e "  Checking missing \033[1;34mTaps\033[0m..."
for tap in cask-fonts command-not-found services; do
  repo=$(brew --repo "homebrew/$tap")
  mirror="$homebrew_tap_mirror/homebrew-$tap.git"
  if [ -d "$repo" ]; then
    url=$(git -C "$repo" remote get-url origin)
    if [[ "$url" != "$mirror" ]]; then
      echo -e "  Replacing remote of \033[1;33mhomebrew/$tap\033[0m to \033[1;34m$mirror\033[0m..."
      brew tap --custom-remote --force-auto-update "homebrew/$tap" "$mirror"
    fi
  else
    echo -e "  Setting up \033[1;33mhomebrew/$tap\033[0m from \033[1;34m$mirror\033[0m..."
    brew tap --custom-remote --force-auto-update "homebrew/$tap" "$mirror"
  fi
done

parse_spec() {
  local spec="$1"
  local name="${spec%%@*}"
  local system="${spec##*@}"
  if [[ "$name" == "$system" ]]; then
    system=""
  fi
  if  [ -z "$system" ] || [[ "$system" == "$(uname -s)" ]]; then
    echo "$name"
  fi
}

installed_formulae="$(brew list --formula)"
required_formulae=(
  # Shell and Command Line tools
  "fish"       # Shell
  "starship"   # Prompt
  "fastfetch"  # System info
  "zoxide"     # Better cd
  "ripgrep"    # Better grep
  "fd"         # Better find
  "bat"        # Better cat
  "bat-extras" # Extras for bat
  "git-delta"  # Better diff pager
  "fzf"        # Fuzzy finder
  "aria2"      # Downloader
  # Programming Languages
  "python"  # Latest Python 3
  "rust"    # Latest Rust
  "juliaup" # Julia installer
  # NeoVim and plugin dependencies
  "neovim"         # NeoVim
  "neovim-remote"  # Remote Control for NeoVim
  "gnu-sed@Darwin" # GNU sed
)

echo -e "  Checking missing \033[1;34mFormulae\033[0m..."
for formula_spec in "${required_formulae[@]}"; do
  formula="$(parse_spec "$formula_spec")"
  if [ -z "$formula" ]; then
    continue
  fi
  if grep -q "formula" <<< "$installed_formulae"; then
    echo -e "  Installing \033[1;33m$formula\033[0m..."
    brew install "$formula"
  fi
done

if [ "$(uname -s)" != "Darwin" ]; then
  echo -e "  Skipping casks on non-Darwin system..."
  exit 0
fi
installed_casks="$(brew list --cask)"
required_casks=(
  "kitty"        # Terminal
  # Fonts
  "font-fira-code"
  "font-victor-mono"
  "font-symbols-only-nerd-font"
)
echo -e "  Checking missing \033[1;34mCasks\033[0m..."
for cask_spec in "${required_casks[@]}"; do
  cask="$(parse_spec "$cask_spec")"
  if [ -z "$cask" ]; then
    continue
  fi
  if grep -q "cask" <<< "$installed_casks"; then
    echo -e "  Installing $cask..."
    brew install --cask "$cask"
  fi
done
