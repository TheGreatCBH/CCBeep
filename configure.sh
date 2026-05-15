#!/usr/bin/env bash
# CCBeep sound configurator
#
# Non-interactive (Claude Code friendly):
#   ./configure.sh --complete Sosumi --error Funk
#   ./configure.sh --complete 12 --error 5          (by number)
#   ./configure.sh --list                            (show sounds)
#   ./configure.sh --test                            (test current config)
#   ./configure.sh --reset                           (restore defaults)
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
    # Number → name (macOS only)
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
        echo "Usage: ./configure.sh --complete <name|number> --error <name|number>"
        echo "       ./configure.sh --complete /path/to/custom.wav"
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
        echo "Usage: ./configure.sh --complete <name> --error <name>"
    else
        echo "  Beep format: frequency:duration  (e.g. 800:200)"
        echo "  Multi-tone:  1000:200,1200:300"
        echo ""
        echo "Usage: ./configure.sh --complete \"1000:200,1200:300\" --error \"400:500\""
    fi
}

save_config() {
    local complete="$1"
    local error="$2"
    python3 - "$CONFIG_FILE" "$complete" "$error" << 'PYEOF'
import sys, json
config_file = sys.argv[1]
complete = sys.argv[2]
error = sys.argv[3]
config = {}
try:
    with open(config_file) as f:
        config = json.load(f)
except: pass
if complete:
    config["complete"] = complete
if error:
    config["error"] = error
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
        echo "No config file yet (using defaults: Purr / Basso)."
    fi
    echo ""
}

# ── Non-interactive mode (--complete / --error / --list / --test) ──────────────
if [ $# -gt 0 ]; then
    complete_val=""
    error_val=""
    do_list=false
    do_test=false

    while [ $# -gt 0 ]; do
        case "$1" in
            --complete|-c)
                complete_val="$(resolve_sound "$2")"
                shift 2
                ;;
            --error|-e)
                error_val="$(resolve_sound "$2")"
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
                echo "Config reset to defaults (Purr / Basso)."
                exit 0
                ;;
            *)
                echo "Unknown flag: $1"
                echo "Usage: ./configure.sh [--complete SOUND] [--error SOUND] [--list] [--test] [--reset]"
                echo "Usage: ./configure.sh [--complete SOUND] [--error SOUND] [--list] [--test]"
                exit 1
                ;;
        esac
    done

    if $do_list; then
        show_list
        exit 0
    fi

    if $do_test; then
        echo "Playing complete sound..."
        "$CCBEEP_DIR/ccbeep.sh" complete
        sleep 1
        echo "Playing error sound..."
        "$CCBEEP_DIR/ccbeep.sh" error
        exit 0
    fi

    if [ -n "$complete_val" ] || [ -n "$error_val" ]; then
        save_config "$complete_val" "$error_val"
        show_current
        echo "Saved. Testing sounds..."
        if [ -n "$complete_val" ]; then
            echo "  complete → $(echo "$complete_val")"
            "$CCBEEP_DIR/ccbeep.sh" complete
        fi
        if [ -n "$error_val" ]; then
            sleep 0.5
            echo "  error    → $(echo "$error_val")"
            "$CCBEEP_DIR/ccbeep.sh" error
        fi
        echo "Done."
        exit 0
    fi

    echo "Nothing to do. Use --complete / --error / --list / --test / --reset"
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

# Pick complete sound
current_complete=""
[ -f "$CONFIG_FILE" ] && current_complete="$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    print(json.load(f).get('complete',''))
" 2>/dev/null || echo "")"

printf "Sound for complete [%s]: " "${current_complete:-Purr}" >&2
read -r choice
complete_val="$(resolve_sound "${choice:-}")"

# Pick error sound
current_error=""
[ -f "$CONFIG_FILE" ] && current_error="$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    print(json.load(f).get('error',''))
" 2>/dev/null || echo "")"

printf "Sound for error    [%s]: " "${current_error:-Basso}" >&2
read -r choice
error_val="$(resolve_sound "${choice:-}")"

save_config "${complete_val:-$current_complete}" "${error_val:-$current_error}"
echo ""
echo "Saved."
echo ""

printf "Test sounds? [Y/n]: " >&2
read -r yn
if [ "$yn" != "n" ] && [ "$yn" != "N" ]; then
    echo "Playing complete..."
    "$CCBEEP_DIR/ccbeep.sh" complete
    sleep 1
    echo "Playing error..."
    "$CCBEEP_DIR/ccbeep.sh" error
fi
echo ""
echo "Done."
