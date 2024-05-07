#!/usr/bin/env bash

# Description: Installations script for dotfiles
# Author: Loong Wang (@wangl-cc)
# LICENSE: MIT

set -e

# color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# color the string
#
# Usage: color "string" "color"
#
# ## Arguments:
#
# - string: The string to color
# - color: The color to use, should be ANSI color code, default to BLUE
color() {
  echo -n "${2:-$BLUE}$1${NC}"
}

# color the string with newline
#
# Usage: colorln "string" "color"
#
# ## Arguments:
#
# - string: The string to color
# - color: The color to use, should be ANSI color code, default to BLUE
colorln() {
  echo "${2:-$BLUE}$1${NC}"
}

# Global log level, from 0 to 5, default to 2.
# 0 is the most verbose, 5 is the least verbose.
# Log level can be change by setting LOGLEVEL environment variable,
# and in the script, you can use `LOGLEVEL=3` to change log level,
# or ((LOGLEVEL++)) to increase log level by 1.
LOGLEVEL=${LOGLEVEL:-2}

# Logging Functions

# show with cyan TRACE prefix, only show when LOGLEVEL <= 0
trace() {
  if [ "$LOGLEVEL" -le 0 ]; then
    echo -e "${CYAN}TRACE:${NC} $*"
  fi
}

# show with purple DEBUG prefix, only show when LOGLEVEL <= 1
debug() {
  if [ "$LOGLEVEL" -le 1 ]; then
    echo -e "${PURPLE}DEBUG:${NC} $*"
  fi
}

# show with no prefix, only show when LOGLEVEL <= 2
info() {
  if [ "$LOGLEVEL" -le 2 ]; then
    echo -e "$@"
  fi
}

# colorized info
ok() {
  info "${GREEN}$*${NC}"
}

# show with yellow WARN prefix, and only show when LOGLEVEL <= 3
warn() {
  if [ "$LOGLEVEL" -le 3 ]; then
    echo -e "${YELLOW}WARN${NC}:  $1"
  fi
}

# show with red ERROR prefix and exit with code 1, only used when LOGLEVEL <= 4
error() {
  if [ "$LOGLEVEL" -le 4 ]; then
    echo -e "${RED}ERROR${NC}: $1>&2"
    exit 1
  fi
}

# ENVIRONMENT VARIABLES
GIT=${GIT-"git"}

__git_can_quiet() {
  while [ $# -gt 0 ]; do
    case "$1" in
      clone|pull|reset|checkout|submodule)
        return 0
        ;;
      -C)
        shift 2
        ;;
      *)
        return 1
    esac
  done
}

git_verbose() {
  local args=("$@")
  if [ "$LOGLEVEL" -ge 3 ]; then
    if __git_can_quiet "${args[0]}"; then
      args=(${args[@]} -q)
    fi
  fi
  trace "$GIT ${args[*]}"
  $GIT "${args[@]}"
}

clone() {
  local temp
  temp=$(mktemp -d)
  cd "$temp"
  # Clone the repository in the temporary directory
  git_verbose clone --no-checkout "$1" "$temp" --branch "$2"
  # Configure the repository
  git_verbose config core.bare false
  git_verbose config core.worktree "$HOME"
  git_verbose config yadm.managed true
  git_verbose config core.sparsecheckout true
  git_verbose config core.sparseCheckoutCone false
  git_verbose sparse-checkout set --no-cone '/*' '!/README.md' '!/LICENSE' '!/install.sh' '!/.github'
  # Move the repository to the home directory
  mv "$temp/.git" "$HOME"
  # Remove the temporary directory
  rm -rf "$temp"
  cd "$HOME"
  git_verbose reset -- .
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

  info "Expand templates"
  ESH_SHELL="/bin/bash" yadm alt

  if [[ -z "$NONINTERACTIVE" && -z "$CODESPACES" ]]; then
    read -rp "Do you want to bootstrap? [y/N] " -n 1; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      yadm bootstrap
    fi
  else
    yadm bootstrap
  fi
}

fetch() {
  local url=$1
  local branch=$2
  local repo="$HOME/.git"
  # clone $url to $repo
  if [ -d "$repo" ]; then
    if [ "$force" = "true" ]; then
      warn "Repository already exists, force clone"
      rm -rf "$repo"
      clone "$url" "$branch"
    else
      # check if remote of $repo is $url
      local remote_url
      remote_url=$($GIT -C "$repo" remote get-url origin)
      if [ "$remote_url" != "$url" ]; then
        error "Repository already exists, but remote is not $url"
      fi
      info "Repository already exists, pull latest changes"
      git_verbose -C "$repo" pull
    fi
  else
    clone "$url" "$branch"
  fi
}

usage() {
cat <<EOM
Usage: $(basename "$0") [options] [command]

Options:
  -p Specify repository protocol (default: https, available: https, ssh)
  -c Specify repository code host (default: github.com)
  -u Specify repository owner (default: wangl-cc)
  -r Specify repository name (default: dotfiles)
  -l Specify repository url (default: generated from -p, -c, -u, -r)
  -b Specify repository branch (default: master)

  -f Force clone repository and overwrite existing one

  -v Verbose output, repeat for more verbosity
  -q Quiet output, repeat for less verbosity

  -h Show this help message and exit

ENVIRONMENT VARIABLES:
  NONINTERACTIVE: If set to any value, do not prompt for confirmation
EOM
}

main() {
  force=false
  local protocol="https"
  local host="github.com"
  local owner="wangl-cc"
  local repo="dotfiles"
  local branch="master"
  local url

  while getopts "p:c:u:r:l:b:fvqh" opt; do
    case $opt in
      p) protocol="$OPTARG";;
      c) host="$OPTARG";;
      u) owner="$OPTARG";;
      r) repo="$OPTARG";;
      l) url="$OPTARG";;
      b) branch="$OPTARG";;

      f) force=true;;

      v) (( LOGLEVEL-- ));;
      q) (( LOGLEVEL++ ));;

      h) usage; exit 0;;
      *) usage; exit 1;;
    esac
  done

  if [ -z "$url" ]; then
    if [ "$protocol" = "https" ]; then
      url="https://$host/$owner/$repo.git"
    elif [ "$protocol" = "ssh" ]; then
      url="git@$host:$owner/$repo.git"
    else
      error "Unknown protocol: $protocol"
    fi
  fi


  export PATH="$HOME/.local/bin:$PATH"

  debug "GIT: $(color "$GIT")"
  debug "PATH: $(color "$PATH")"
  debug "LOGLEVEL: $(color "$LOGLEVEL")"
  debug "force: $(color "$force")"
  debug "owner: $(color "$owner")"
  debug "repo: $(color "$repo")"
  debug "branch: $(color "$branch")"
  debug "url: $(color "$url")"

  fetch "$url" "$branch"
}

main "$@"
