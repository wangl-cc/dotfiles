#!/usr/bin/env bash

# Send SIGUSR1 to nvim to trigger background update
killall -USR1 nvim 2>/dev/null
