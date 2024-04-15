#!/bin/bash

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

# verbose defaults write
# check if the value is already set
# if not, set it and print the command
defaults_write() {
  local domain="$1"
  local key="$2"
  local type="$3"
  local value="$4"
  local current_value
  current_value="$(defaults read "$domain" "$key" 2>/dev/null)"
  if [[ "$type" == "-bool" ]]; then
    if [[ "$current_value" == "1" ]]; then
      current_value="true"
    elif [[ "$current_value" == "0" ]]; then
      current_value="false"
    fi
  fi
  if [[ "$current_value" != "$value" ]]; then
    echo_indent "Setting $(colorize 35 "$domain") $(colorize 33 "$key") to $(colorize 34 "$value")"
    defaults write "$domain" "$key" "$type" "$value"
  fi
}


# Configure macOS application with defaults write
# reference: https://macos-defaults.com

echo

echo_setup "macOS defaults"

echo_setup "Input Automation"
  defaults_write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
  defaults_write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
  defaults_write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
  defaults_write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
  defaults_write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
echo_done

echo_setup "Trackpad"
for domain in com.apple.driver.AppleBluetoothMultitouch.trackpad \
  com.apple.AppleMultitouchTrackpad; do
  ## enable tap to click
  defaults_write "$domain" Clicking -bool true
  ## twi finger tap to emulate right click
  defaults_write "$domain" TrackpadRightClick -bool true
  defaults_write "$domain" TrackpadTwoFingerDoubleTapGesture -bool true
  ## two finger edge swipe
  defaults_write "$domain" TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3
  ## three finger drag
  defaults_write "$domain" TrackpadThreeFingerDrag -int 1
  defaults_write "$domain" TrackpadThreeFingerHorizSwipeGesture -int 0
  defaults_write "$domain" TrackpadThreeFingerVertSwipeGesture -int 0
  ## three finger tap for search
  defaults_write "$domain" TrackpadThreeFingerTapGesture -int 2
  ## four finger swipe gestures
  defaults_write "$domain" TrackpadFourFingerHorizSwipeGesture -int 2
  defaults_write "$domain" TrackpadFourFingerVertSwipeGesture -int 2
  ## four finger pinch gestures
  defaults_write "$domain" TrackpadFourFingerPinchGesture -int 2
done
echo_done

echo_setup "Dock"
  # autohide dock
  defaults_write com.apple.dock autohide -bool true
  # disable dock magnification
  defaults_write com.apple.dock magnification -bool false
  # dock size
  defaults_write com.apple.dock tilesize -int 48
  # hot corners
  defaults_write com.apple.dock wvous-bl-corner -int 11
  defaults_write com.apple.dock wvous-bl-modifier -int 0
echo_done

echo_setup "Finder"
  # show on desktop
  defaults_write com.apple.finder ShowHardDrivesOnDesktop -bool false
  defaults_write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
  defaults_write com.apple.finder ShowRemovableMediaOnDesktop -bool true
  defaults_write com.apple.finder ShowMountedServersOnDesktop -bool true
  # show path bar and hide status bar
  defaults_write com.apple.finder ShowPathbar -bool true
  defaults_write com.apple.finder ShowStatusBar -bool false
  # Keep folders on top when sorting by name
  defaults_write com.apple.finder _FXSortFoldersFirst -bool true
  # Remove items from the Trash after 30 days
  defaults_write com.apple.finder FXRemoveOldTrashItems -bool true
  # new finder windows open in home directory
  defaults_write com.apple.finder NewWindowTarget -string "PfHm"
  # search the current folder by default
  defaults_write com.apple.finder FXDefaultSearchScope -string "SCcf"
  # don't save to iCloud by default
  defaults_write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
echo_done

echo_setup "Safari"
  # don't open safe files automatically
  defaults_write com.apple.Safari AutoOpenSafeDownloads -bool false
  # open new windows with start page
  defaults_write com.apple.Safari NewWindowBehavior -int 4
  # open new tabs with start page
  defaults_write com.apple.Safari NewTabBehavior -int 4
  # campact tab layout
  defaults_write com.apple.Safari ShowStandaloneTabBar -bool false
  # don't warn about fraudulent websites, this is a privacy concern
  # when enabled, websites will be uploaded to check if they are fraudulent
  defaults_write com.apple.Safari WarnAboutFraudulentWebsites -bool false
echo_done

echo_done
