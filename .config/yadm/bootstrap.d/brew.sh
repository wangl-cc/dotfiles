set -e

colorize() {
  # shellcheck disable=SC2028
  echo "\033[1;${1}m${2}\033[0m"
}

CURRENT_INDENT=${CURRENT_INDENT:-0}

echo_indent() {
  for ((i = 0; i < CURRENT_INDENT; i++)); do
    echo -n "  "
  done
  echo -e "$@"
}

echo_title() {
  echo_indent "$(colorize "$ACTION_COLOR" "$1")" "$(colorize "$TARGET_COLOR" "$2")"
  CURRENT_INDENT=$((CURRENT_INDENT + 1))
}

echo_done() {
  CURRENT_INDENT=$((CURRENT_INDENT - 1))
  echo_indent "$(colorize "$ACTION_COLOR" "Done")!"
}

echo_setup() {
  echo_title "Setting up" "$1"
}

echo
echo_setup "Homebrew"

if [ -n "$HOMEBREW_MIRROR_DOMAIN" ]; then
  export HOMEBREW_GIT_REMOTE="$HOMEBREW_MIRROR_DOMAIN/brew.git"
  export HOMEBREW_API_DOMAIN="$HOMEBREW_MIRROR_DOMAIN/homebrew-bottles/api"
  export HOMEBREW_BOTTLE_DOMAIN="$HOMEBREW_MIRROR_DOMAIN/homebrew-bottles"
fi


echo_title "Checking" "Homebrew git remote"
local_git_remote="$(git -C "$(brew --repo)" remote get-url origin)"
if [ -n "$HOMEBREW_GIT_REMOTE" ] && [[ "$local_git_remote" != "$HOMEBREW_GIT_REMOTE" ]]; then
  echo_indent "Changing git remote to" "$(colorize 33 "$HOMEBREW_GIT_REMOTE")"
  git -C "$(brew --repo)" remote set-url origin "$HOMEBREW_GIT_REMOTE"
  brew update
fi
echo_done

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

echo_title "Checking" "missing formulae"
# PERF: we iterate over all installed formulae for each required formula
# this is not efficient, but it's simple and works not bad

# WARN: version of required formulae (e.g. python@3.9) is not allowed
# and the version of installed formulae will be ignored

installed_formulae=()
while IFS='' read -r formula; do
  installed_formulae+=("$formula")
done < <(brew list --formula)

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
  "juliaup" # Julia installer
  # NeoVim and plugin dependencies
  "neovim"         # NeoVim
  "neovim-remote"  # Remote Control for NeoVim
  "gnu-sed@Darwin" # GNU sed
)

missing_formulae=()
for formula_spec in "${required_formulae[@]}"; do
  formula="$(parse_spec "$formula_spec")"
  if [ -z "$formula" ]; then
    continue
  fi
  for installed_formula in "${installed_formulae[@]}"; do
    installed_formula="${installed_formula%%@*}"
    if [[ "$formula" == "$installed_formula" ]]; then
      continue 2
    fi
  done
  echo_indent "Detected missing formula" "$(colorize 33 "$formula")"
  missing_formulae+=("$formula")
done
echo_done

if [ "${#missing_formulae[@]}" -gt 0 ]; then
  echo_title "Installing" "missing formulae"
  brew install "${missing_formulae[@]}"
  echo_done
fi

echo_done
