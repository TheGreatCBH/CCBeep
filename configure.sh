#!/usr/bin/env bash
# CCBeep sound configurator
#
# Non-interactive (Claude Code friendly):
#   ./configure.sh --sound Sosumi      set sound by name
#   ./configure.sh --sound 12          set sound by number (macOS)
#   ./configure.sh --sound /path/to/custom.wav
#   ./configure.sh --list              show available sounds
#   ./configure.sh --test              play current sound
#   ./configure.sh --reset             restore default (Purr)
#
# Interactive (terminal only):
#   ./configure.sh
set -euo pipefail

CCBEEP_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$HOME/.ccbeep.json"

# ── Detect OS & collect sounds ─────────────────────────────────────────────────
case "$(uname -s)" in
    Darwin)  OS="macos"   ;;
    Linux)   OS="linux"   ;;
    CYGWIN*|MINGW*|MSYS*) OS="windows" ;;
    *)       echo "Unsupported OS"; exit 1 ;;
esac

SOUNDS=()
if [ "$OS" = "macos" ]; then
    for f in /System/Library/Sounds/*.aiff; do
        SOUNDS+=("$(basename "$f" .aiff)")
    done
fi

# ── Helpers ────────────────────────────────────────────────────────────────────
resolve_sound() {
    local input="$1"
    if [[ "$input" =~ ^[0-9]+$ ]] && [ "$OS" = "macos" ] && [ "$input" -ge 1 ] && [ "$input" -le "${#SOUNDS[@]}" ]; then
        echo "${SOUNDS[$((input-1))]}"
    else
        echo "$input"
    fi
}

show_list() {
    echo "Available sounds:"
    echo ""
    if [ "$OS" = "macos" ]; then
        for i in "${!SOUNDS[@]}"; do
            printf "  %2d) %-12s" "$((i+1))" "${SOUNDS[$i]}"
            if [ $(( (i+1) % 4 )) -eq 0 ]; then echo ""; fi
        done
        echo ""
        echo ""
        echo "Usage: ./configure.sh --sound NAME|NUM"
        echo "       ./configure.sh --sound /path/to/custom.wav"
    elif [ "$OS" = "linux" ]; then
        for d in /usr/share/sounds/freedesktop/stereo \
                 /usr/share/sounds/ubuntu/stereo \
                 /usr/share/sounds/gnome/default/alerts; do
            if [ -d "$d" ]; then
                echo "  $d:"
                ls "$d" 2>/dev/null | while read -r f; do echo "    $f"; done || true
            fi
        done
        echo ""
        echo "Usage: ./configure.sh --sound NAME"
    else
        echo "  Beep format: frequency:duration  (e.g. 800:200)"
        echo "  Multi-tone:  1000:200,1200:300"
        echo ""
        echo "Usage: ./configure.sh --sound \"1000:200,1200:300\""
    fi
}

save_config() {
    local sound="$1"
    python3 - "$CONFIG_FILE" "$sound" << 'PYEOF'
import sys, json
config_file = sys.argv[1]
sound = sys.argv[2]
config = {}
try:
    with open(config_file) as f:
        config = json.load(f)
except: pass
if sound:
    config["sound"] = sound
with open(config_file, "w") as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF
}

show_current() {
    if [ -f "$CONFIG_FILE" ]; then
        echo "Current config:"
        cat "$CONFIG_FILE"
    else
        echo "No config file yet (using default: Purr)."
    fi
    echo ""
}

# ── Non-interactive mode ───────────────────────────────────────────────────────
if [ $# -gt 0 ]; then
    sound_val=""
    do_list=false
    do_test=false

    while [ $# -gt 0 ]; do
        case "$1" in
            --sound|-s)
                sound_val="$(resolve_sound "$2")"
                shift 2
                ;;
            --list|-l)
                do_list=true
                shift
                ;;
            --test|-t)
                do_test=true
                shift
                ;;
            --reset)
                rm -f "$CONFIG_FILE"
                echo "Config reset to default (Purr)."
                exit 0
                ;;
            *)
                echo "Unknown flag: $1"
                echo "Usage: ./configure.sh [--sound SOUND] [--list] [--test] [--reset]"
                exit 1
                ;;
        esac
    done

    if $do_list; then
        show_list
        exit 0
    fi

    if $do_test; then
        echo "Playing current sound..."
        "$CCBEEP_DIR/ccbeep.sh" stop
        exit 0
    fi

    if [ -n "$sound_val" ]; then
        save_config "$sound_val"
        show_current
        echo "Saved. Testing..."
        "$CCBEEP_DIR/ccbeep.sh" stop
        echo "Done."
        exit 0
    fi

    echo "Nothing to do. Use --sound / --list / --test / --reset"
    exit 0
fi

# ── Interactive mode (no flags) ────────────────────────────────────────────────
echo ""
echo "  CCBeep — Sound Configuration"
echo "  ============================="
echo ""
show_current
show_list
echo ""
echo "  ── Quick setup (non-interactive) ──"
echo "  ./configure.sh --sound NAME|NUM"
echo "  ./configure.sh --list          show sounds"
echo "  ./configure.sh --test          test current sound"
echo "  ./configure.sh --reset         restore default"
echo ""

current_sound=""
[ -f "$CONFIG_FILE" ] && current_sound="$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    c = json.load(f)
    print(c.get('sound') or c.get('stop', ''))
" 2>/dev/null || echo "")"

printf "Sound [%s]: " "${current_sound:-Purr}" >&2
read -r choice
sound_val="$(resolve_sound "${choice:-}")"

save_config "${sound_val:-$current_sound}"
echo ""
echo "Saved."
echo ""

printf "Test sound? [Y/n]: " >&2
read -r yn
if [ "$yn" != "n" ] && [ "$yn" != "N" ]; then
    "$CCBEEP_DIR/ccbeep.sh" stop
fi
echo ""
echo "Done."
