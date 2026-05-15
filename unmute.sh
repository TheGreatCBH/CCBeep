#!/usr/bin/env bash
# CCBee unmute — re-enable sound notifications
set -euo pipefail

MUTE_FILE="$HOME/.ccbee_mute"

if [ -f "$MUTE_FILE" ]; then
    rm -f "$MUTE_FILE"
    echo "Unmuted. Sound notifications are back on."
else
    echo "Not currently muted."
fi
