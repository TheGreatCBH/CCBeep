#!/usr/bin/env bash
# CCBeep interactive sound configurator
# Usage: ./configure.sh
set -euo pipefail

CCBEEP_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$HOME/.ccbeep.json"

# ── Detect OS ──────────────────────────────────────────────────────────────────
case "$(uname -s)" in
    Darwin)  OS="macos"   ;;
    Linux)   OS="linux"   ;;
    CYGWIN*|MINGW*|MSYS*) OS="windows" ;;
    *)       echo "Unsupported OS"; exit 1 ;;
esac

echo ""
echo "  CCBeep — Sound Configuration"
echo "  ============================="
echo ""

# ── Show current config ───────────────────────────────────────────────────────
if [ -f "$CONFIG_FILE" ]; then
    echo "Current config (~/.ccbeep.json):"
    cat "$CONFIG_FILE"
    echo ""
else
    echo "No config file yet (using built-in defaults)."
    echo ""
fi

# ── Show available sounds ──────────────────────────────────────────────────────
if [ "$OS" = "macos" ]; then
    echo "Available sounds (pick a name):"
    echo ""
    sounds=()
    for f in /System/Library/Sounds/*.aiff; do
        sounds+=("$(basename "$f" .aiff)")
    done
    # Calculate column width
    for i in "${!sounds[@]}"; do
        printf "  %2d) %-12s" "$((i+1))" "${sounds[$i]}"
        if [ $(( (i+1) % 4 )) -eq 0 ]; then echo ""; fi
    done
    echo ""
    echo ""
    echo "  Or enter a full file path to a custom sound file."
elif [ "$OS" = "linux" ]; then
    echo "Available sounds:"
    for d in /usr/share/sounds/freedesktop/stereo \
             /usr/share/sounds/ubuntu/stereo \
             /usr/share/sounds/gnome/default/alerts; do
        if [ -d "$d" ]; then
            echo ""
            echo "  $d:"
            ls "$d" 2>/dev/null | while read -r f; do echo "    $f"; done || true
        fi
    done
    echo ""
    echo "  Enter a sound name or full file path."
else
    echo "Windows: enter Beep frequency:duration"
    echo "  Single: 800:200"
    echo "  Double: 1000:200,1200:300"
    echo ""
fi

# ── Pick sound for each event ──────────────────────────────────────────────────
pick_sound() {
    local event="$1"
    local label="$2"
    local default="$3"
    local current=""

    if [ -f "$CONFIG_FILE" ]; then
        current="$(python3 -c "
import json
try:
    with open('$CONFIG_FILE') as f:
        print(json.load(f).get('${event}',''))
except: pass
" 2>/dev/null || echo "")"
    fi

    printf "Sound for %s [%s]: " "$label" "${current:-$default}" >&2
    read -r choice

    if [ -n "$choice" ]; then
        # Check if it's a number (macOS)
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$OS" = "macos" ] && [ "$choice" -le "${#sounds[@]}" ]; then
            echo "${sounds[$((choice-1))]}"
        else
            echo "$choice"
        fi
    else
        echo "${current:-}"
    fi
}

complete_sound="$(pick_sound "complete" "task complete" "Purr")"
error_sound="$(pick_sound "error" "task error" "Basso")"

# ── Write config ───────────────────────────────────────────────────────────────
python3 - "$CONFIG_FILE" "$complete_sound" "$error_sound" << 'PYEOF'
import sys, json
config_file = sys.argv[1]
complete = sys.argv[2]
error = sys.argv[3]

config = {}
# Load existing if present
try:
    with open(config_file) as f:
        config = json.load(f)
except:
    pass

if complete:
    config["complete"] = complete
if error:
    config["error"] = error

with open(config_file, "w") as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF

echo ""
echo "Config saved to ~/.ccbeep.json"

# ── Test sounds ────────────────────────────────────────────────────────────────
echo ""
printf "Test sounds? [Y/n]: " >&2
read -r test_choice
if [ "$test_choice" != "n" ] && [ "$test_choice" != "N" ]; then
    echo ""
    echo "Playing complete sound..."
    "$CCBEEP_DIR/ccbeep.sh" complete &
    sleep 1
    echo "Playing error sound..."
    "$CCBEEP_DIR/ccbeep.sh" error &
    sleep 1
fi

echo ""
echo "Done. Use './mute.sh' to temporarily silence, './unmute.sh' to re-enable."
