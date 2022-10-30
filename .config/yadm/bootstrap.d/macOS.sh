#!/bin/bash

echo -e "\n\033[1;35mSetting up macOS defaults...\033[0m"

defaults_verbose() {
  echo "  defaults $*"
  defaults "$@"
}

# iterm2
## set iterm2 config folder
defaults_verbose write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/.config/iterm2"
## enable custom folder
defaults_verbose write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

# disbale some annoying input automation
defaults_verbose write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults_verbose write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults_verbose write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults_verbose write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# trackpad
for domain in com.apple.driver.AppleBluetoothMultitouch.trackpad \
  com.apple.AppleMultitouchTrackpad; do
  ## enable tap to click
  defaults_verbose write "$domain" Clicking -bool true
  ## twi finger tap to emulate right click
  defaults_verbose write "$domain" TrackpadRightClick -bool true
  defaults_verbose write "$domain" TrackpadTwoFingerDoubleTapGesture -bool true
  ## two finger edge swipe
  defaults_verbose write "$domain" TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3
  ## three finger drag
  defaults_verbose write "$domain" TrackpadThreeFingerDrag -int 1
  defaults_verbose write "$domain" TrackpadThreeFingerHorizSwipeGesture -int 0
  defaults_verbose write "$domain" TrackpadThreeFingerVertSwipeGesture -int 0
  ## three finger tap for search
  defaults_verbose write "$domain" TrackpadThreeFingerTapGesture -int 2
  ## four finger swipe gestures
  defaults_verbose write "$domain" TrackpadFourFingerHorizSwipeGesture -int 2
  defaults_verbose write "$domain" TrackpadFourFingerVertSwipeGesture -int 2
  ## four finger pinch gestures
  defaults_verbose write "$domain" TrackpadFourFingerPinchGesture -int 2
done

# dock
## disbale magnification
defaults_verbose write com.apple.dock magnification -bool false

# vscode
## enable keys repeat when hold
defaults_verbose write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
# don't save to iCloud by default
defaults_verbose write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# vim:ts=2:sw=2:et
