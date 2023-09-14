#!/bin/bash

echo -e "\n\033[1;35mSetting up macOS defaults...\033[0m"

# verbose defaults write
# check if the value is already set
# if not, set it and print the command
defaults_write() {
  local domain="$1"
  local key="$2"
  local type="$3"
  local value="$4"
  local current_value="$(defaults read "$domain" "$key" 2>/dev/null)"
  if [[ "$type" == "-bool" ]]; then
    if [[ "$current_value" == "1" ]]; then
      current_value="true"
    elif [[ "$current_value" == "0" ]]; then
      current_value="false"
    fi
  fi
  if [[ "$current_value" != "$value" ]]; then
    echo -e "  defaults write \033[1;33m$domain\033[0m \033[1;34m$key\033[0m \033[1;32m$type\033[0m \033[1;36m$value\033[0m"
    defaults write "$domain" "$key" "$type" "$value"
  fi
}

# iterm2
## set iterm2 config folder
defaults_write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/.config/iterm2"
## enable custom folder
defaults_write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

# disbale some annoying input automation
defaults_write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults_write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults_write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults_write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# don't save to iCloud by default
defaults_write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# trackpad
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

# dock
## disbale magnification
defaults_write com.apple.dock magnification -bool false

# vscode
## enable keys repeat when hold
defaults_write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false

# vim:ts=2:sw=2:et
