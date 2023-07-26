#!/bin/bash

cd "$HOME/.local/bin" || exit
make dark-mode-notify

cd "$HOME/.config/dark-mode-notify" || exit
make launchd.plist
if launchctl list | grep -q dark-mode-notify; then
    launchctl unload launchd.plist
fi
launchctl load launchd.plist
