#!/bin/bash

# Color Codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Variables
GIT=${GIT-"git"}
export PATH="$HOME/.local/bin:$PATH"

# Logging
LOG_LEVEL=2
trace() {
  if [ $LOG_LEVEL -le 0 ]; then
    echo -e "${CYAN}TRACE:${NC} $1"
  fi
}
debug() {
  if [ $LOG_LEVEL -le 1 ]; then
    echo -e "${PURPLE}DEBUG:${NC} $1"
  fi
}
info() {
  if [ $LOG_LEVEL -le 2 ]; then
    echo -e "$1"
  fi
}
warn() {
  if [ $LOG_LEVEL -le 3 ]; then
    echo -e "${YELLOW}WARN${NC}:  $1"
  fi
}
error() {
  if [ $LOG_LEVEL -le 4 ]; then
    echo -e "${RED}ERROR${NC}: $1>&2"
    exit 1
  fi
}

color() {
  echo "${2:-$BLUE}$1${NC}"
}

ok() {
  info "$(color "$1" "$GREEN")"
}

# Logging for git
can_quiet() {
  subcmd=$1
  $GIT "$subcmd" -h | grep -q -- --quiet
}
can_verbose() {
  subcmd=$1
  $GIT "$subcmd" -h | grep -q -- --verbose
}
git_verbose() {
  trace "$GIT $*"
  if [[ $LOG_LEVEL -le 2 && $(can_verbose "$1") ]]; then
    $GIT "$@" --verbose
  elif [[ $LOG_LEVEL -ge 4 && $(can_quiet "$1") ]]; then
    $GIT "$@" --quiet
  else
    $GIT "$@"
  fi
}

config() {
  git_verbose config core.bare false
  git_verbose config core.worktree "$HOME"
  git_verbose config yadm.managed true
  git_verbose config core.sparsecheckout true
  git_verbose config core.sparseCheckoutCone false
  git_verbose sparse-checkout set --no-cone '/*' '!/README.md' '!/LICENSE' '!/install.sh' '!/.github'
}


clone_core() {
  local temp
  temp=$(mktemp -d)
  cd "$temp" || error "Unable to change to temp directory: $temp"
  git_verbose clone --no-checkout "$1" "$temp" --branch "$2" ||
    error "Unable to clone repository $(color "$1") with branch $(color "$2")"
  config || error "Unable to configure repository"
  mv "$temp/.git" "$HOME" || error "Unable to move .git directory"
  rm -rf "$temp"
  cd ~ || error "Unable to change to home directory: $HOME"
  git_verbose reset HEAD
  git_verbose submodule update --init --recursive
  $GIT ls-files --deleted | while IFS= read -r file; do
    git_verbose checkout -- ":/$file"
  done
  if [ -n "$($GIT ls-files --modified)" ]; then
    warn "Local files with content that differs from the ones just cloned were found."
    warn "They have been left unmodified."
    warn "Please review and resolve any differences appropriately."
  fi
  ok "Clone succeed"
}

clone() {
  force=$1
  url=$2
  branch=$3
  repo="$HOME/.git"
  if [ -d "repo" ]; then if [ "$force" = "true" ]; then
      warn "Repository already exists, force clone"
      rm -rf "$repo"
      clone_core "$url" "$branch"
    else
      warn "Repository already exists, pull latest changes"
      git_verbose -C "$repo" pull --quiet
    fi
  else
    clone_core "$url" "$branch"
  fi
}

usage() {
cat <<EOM
Usage: $(basename "$0") [options] [command]
Options:
  -h Show this help message and exit
  -f Force clone repository and overwrite existing one
  -v Verbose output, repeat for more verbosity
  -q Quiet output, repeat for less verbosity
  -u Specify repository owner
  -r Specify repository name
  -b Specify repository branch
  -l Specify repository url
EOM
}

main() {
  while getopts "hfmvqu:r:b:l:" opt; do
    case $opt in
      h) usage; exit 0;;
      f) force=true;;
      v) (( LOG_LEVEL-- ));;
      q) (( LOG_LEVEL++ ));;
      u) owner="$OPTARG";;
      r) repo="$OPTARG";;
      b) branch="$OPTARG";;
      l) url="$OPTARG";;
      *) usage; exit 1;;
    esac
  done

  force=${force-"false"}
  owner=${owner:-"wangl-cc"}
  repo=${repo:-"dotfiles"}
  branch=${branch:-"master"}
  url=${url:-"https://github.com/$owner/$repo.git"}
  
  debug "GIT: $(color "$GIT")"
  debug "PATH: $(color "$PATH")"
  debug "LOG_LEVEL: $(color "$LOG_LEVEL")"
  debug "force: $(color "$force")"
  debug "owner: $(color "$owner")"
  debug "repo: $(color "$repo")"
  debug "branch: $(color "$branch")"
  debug "url: $(color "$url")"

  clone "$force" "$url" "$branch"
  link_yadm
  export ESH_SHELL="/bin/bash"
  yadm alt
  yadm bootstrap
}

main "$@"
