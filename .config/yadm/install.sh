#!/bin/bash

GIT=${GIT-"git"}
GITHUB=${GITHUB-"https://github.com/"}
OWNER=${OWNER-"wangl-cc"}
REPO=${REPO-"dotfiles"}
REPO_URL=${REPO_URL-"$GITHUB$OWNER/$REPO.git"}
REPO_DIR="$HOME"
REPO_DEST="$REPO_DIR/.git"

# make sure $HOME/.local/bin in PATH
# where yadm and esh is located
export PATH="$HOME/.local/bin:$PATH"

config_repo() {
  $GIT config core.bare false
  $GIT config core.worktree "$HOME"
  $GIT config yadm.managed true
  $GIT config core.sparsecheckout true
  $GIT config core.sparseCheckoutCone false
  $GIT sparse-checkout set --no-cone '/*' '!/README.md' '!/LICENSE' '!/install.sh' '!/.github'
}

clone_repo() {
  if [ -d "$REPO_DEST" ]; then
    echo "Repository already exists, pull latest changes."
    $GIT -C "$REPO_DIR" pull
  else
    temp=$(mktemp -d)
    [ -d "$temp" ] || echo "Failed to create temp directory." && exit 1
    cd "$temp" &&
    $GIT clone --no-checkout "$REPO_URL" &&
    config_repo &&
    mv "$temp/.git" "$REPO_DIR" &&
    cd ~ &&
    $GIT reset HEAD &&
    yadm bootstrap
    rm -rf "$temp"
  fi
}

YADM_DATA="$HOME/.local/share/yadm"
# create a link to yadm repo for $REPO_DEST
fake_repo() { # fake git for yadm
  if ! [ -e "$YADM_DATA/repo.git" ]; then
    print -P "Create fake git for yadm."
    if ! [ -d "$YADM_DATA" ]; then
      mkdir -p "$YADM_DATA"
    fi
    ln -s "$REPO_DEST" "$YADM_DATA/repo.git"
  fi
}

clone_repo
fake_repo
