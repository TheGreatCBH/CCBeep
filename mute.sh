#!/usr/bin/env bash
# CCBeep mute — temporarily silence sound notifications
#
# Usage:
#   ./mute.sh           Mute permanently (until unmute.sh is run)
#   ./mute.sh 2h        Mute for 2 hours, then auto-unmute
#   ./mute.sh 30m       Mute for 30 minutes
#   ./mute.sh 1d        Mute for 1 day
set -euo pipefail

MUTE_FILE="$HOME/.ccbee_mute"

if [ -f "$MUTE_FILE" ]; then
    echo "Already muted. To unmute: ./unmute.sh"
    exit 0
fi

if [ $# -gt 0 ]; then
    duration="$1"
    # Parse duration: 2h, 30m, 1d
    seconds=0
    case "$duration" in
        *h) seconds=$(( ${duration%h} * 3600 )) ;;
        *m) seconds=$(( ${duration%m} * 60 ))   ;;
        *d) seconds=$(( ${duration%d} * 86400 )) ;;
        *s) seconds=${duration%s} ;;
        *)  echo "Usage: mute.sh [DURATION]  e.g. 2h, 30m, 1d"; exit 1 ;;
    esac
    expiry=$(( $(date +%s) + seconds ))
    echo "$expiry" > "$MUTE_FILE"
    echo "Muted for $duration (until $(date -r "$expiry" '+%H:%M:%S'))"
else
    touch "$MUTE_FILE"
    echo "Muted. Run ./unmute.sh to unmute."
fi
