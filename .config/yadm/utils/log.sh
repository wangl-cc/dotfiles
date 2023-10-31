#!/usr/bin/env bash

# Library for logging

[ -z "$__LOG_SOURCED" ] || return 0

__LOG_SOURCED=1

# load color library
__LOG_SRC_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))
source $__LOG_SRC_DIR/color.sh

# Global log level, from 0 to 5, default to 2.
# 0 is the most verbose, 5 is the least verbose.
# Log level can be change by setting LOGLEVEL environment variable,
# and in the script, you can use `LOGLEVEL=3` to change log level,
# or ((LOGLEVEL++)) to increase log level by 1.
LOGLEVEL=${LOGLEVEL:-2}

# Logging Functions

# show with cyan TRACE prefix, only show when LOGLEVEL <= 0
trace() {
  if [ $LOGLEVEL -le 0 ]; then
    echo -e "${CYAN}TRACE:${NC} $@"
  fi
}

# show with purple DEBUG prefix, only show when LOGLEVEL <= 1
debug() {
  if [ $LOGLEVEL -le 1 ]; then
    echo -e "${PURPLE}DEBUG:${NC} $@"
  fi
}

# show with no prefix, only show when LOGLEVEL <= 2
info() {
  if [ $LOGLEVEL -le 2 ]; then
    echo -e "$@"
  fi
}

# colorized info
ok() {
  info "${GREEN}$@${NC}"
}

# show with yellow WARN prefix, and only show when LOGLEVEL <= 3
warn() {
  if [ $LOGLEVEL -le 3 ]; then
    echo -e "${YELLOW}WARN${NC}:  $1"
  fi
}

# show with red ERROR prefix and exit with code 1, only used when LOGLEVEL <= 4
error() {
  if [ $LOGLEVEL -le 4 ]; then
    echo -e "${RED}ERROR${NC}: $1>&2"
    exit 1
  fi
}
