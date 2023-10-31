#!/usr/bin/env bash

# Library for logging

[ -z "$__COLOR_SOURCED" ] || return 0

__COLOR_SOURCED=1

# Color Codes
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
  echo -ne "${2:-$BLUE}$1${NC}"
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
  echo -e "${2:-$BLUE}$1${NC}"
}
