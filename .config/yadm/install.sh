#!/usr/bin/env bash

# Description: Installations script for dotfiles
# Author: Loong Wang (@wangl-cc)
# LICENSE: MIT

__INSTALL_SRC_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))

# Load libraries
source $__INSTALL_SRC_DIR/utils/log.sh

set -e

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
  if [ $LOGLEVEL -ge 3 ]; then
    if __git_can_quiet "${args[0]}"; then
      args=(${args[@]} -q)
    fi
  fi
  trace "$GIT ${args[@]}"
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
      local remote_url=$($GIT -C "$repo" remote get-url origin)
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
    if [ $protocol = "https" ]; then
      url="https://$host/$owner/$repo.git"
    elif [ $protocol = "ssh" ]; then
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
