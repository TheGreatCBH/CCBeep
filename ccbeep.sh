#!/usr/bin/env bash
# CCBeep - Sound notifications for Claude Code events
# https://github.com/TheGreatCBH/CCBeep
#
# Usage:
#   ccbeep.sh complete               Play completion sound (with defaults)
#   ccbeep.sh complete --sound Ping  Override sound for this call
#   ccbeep.sh error                  Play error sound
#   ccbeep.sh stop                   Read stdin JSON, auto-detect complete/error
#   ccbeep.sh list                   List available sounds for current OS
#
# Persistent customization: create ~/.ccbeep.json
#   { "complete": "Sosumi", "error": "Funk" }
#
# Priority: --sound flag > ~/.ccbeep.json > built-in defaults
set -euo pipefail

CONFIG_FILE="$HOME/.ccbeep.json"

# ── Mute check ──────────────────────────────────────────────────────────────────
MUTE_FILE="$HOME/.ccbeep_mute"
if [ -f "$MUTE_FILE" ]; then
    expiry="$(cat "$MUTE_FILE" 2>/dev/null || true)"
    if [ -n "$expiry" ] && [ "$expiry" -gt 0 ] 2>/dev/null; then
        if [ "$(date +%s)" -gt "$expiry" ]; then
            rm -f "$MUTE_FILE"
        else
            exit 0
        fi
    else
        exit 0
    fi
fi

# ── OS detection ──────────────────────────────────────────────────────────────
detect_os() {
    case "$(uname -s)" in
        Darwin)  echo "macos"   ;;
        Linux)   echo "linux"   ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *)       echo "unknown" ;;
    esac
}

# ── Load config from ~/.ccbeep.json ─────────────────────────────────────────────
load_config() {
    local event="$1"
    if [ ! -f "$CONFIG_FILE" ]; then
        return 0
    fi
    python3 -c "
import json
try:
    with open('$CONFIG_FILE') as f:
        config = json.load(f)
    val = config.get('${event}', '')
    if isinstance(val, str):
        print(val)
except:
    pass
" 2>/dev/null
}

# ── macOS ──────────────────────────────────────────────────────────────────────
sound_macos() {
    local event="$1"
    local override="${2:-}"

    local sound_name=""
    if [ -n "$override" ]; then
        sound_name="$override"
    else
        case "$event" in
            complete) sound_name="Purr"  ;;
            error)    sound_name="Basso" ;;
            prompt)   sound_name="Glass" ;;
            *)        sound_name="Glass" ;;
        esac
    fi

    if [[ "$sound_name" == */* ]]; then
        # Custom file path
        if [ -f "$sound_name" ]; then
            afplay "$sound_name" &
        fi
    else
        # System sound name
        local sound_file="/System/Library/Sounds/${sound_name}.aiff"
        if [ -f "$sound_file" ]; then
            afplay "$sound_file" &
        else
            echo -e '\a'
        fi
    fi
}

# ── Linux ──────────────────────────────────────────────────────────────────────
sound_linux() {
    local event="$1"
    local override="${2:-}"

    # Resolve sound name/file
    local sound_file=""
    if [ -n "$override" ]; then
        if [[ "$override" == */* ]]; then
            sound_file="$override"
        else
            # Search sound theme dirs
            for d in /usr/share/sounds/freedesktop/stereo \
                     /usr/share/sounds/ubuntu/stereo \
                     /usr/share/sounds/gnome/default/alerts; do
                if [ -f "$d/${override}.oga" ]; then
                    sound_file="$d/${override}.oga"
                    break
                fi
                if [ -f "$d/$override" ]; then
                    sound_file="$d/$override"
                    break
                fi
            done
        fi
    fi

    if [ -z "$sound_file" ]; then
        # Built-in defaults
        local sound_dir="/usr/share/sounds/freedesktop/stereo"
        case "$event" in
            complete) sound_file="$sound_dir/complete.oga"   ;;
            error)    sound_file="$sound_dir/dialog-error.oga" ;;
            prompt)   sound_file="$sound_dir/message.oga"    ;;
            *)        sound_file="$sound_dir/message.oga"    ;;
        esac
    fi

    if [ -f "$sound_file" ]; then
        if command -v paplay &>/dev/null; then
            paplay "$sound_file" &
        elif command -v aplay &>/dev/null; then
            aplay "$sound_file" &>/dev/null &
        else
            echo -e '\a'
        fi
    else
        echo -e '\a'
    fi
}

# ── Windows ────────────────────────────────────────────────────────────────────
sound_windows() {
    local event="$1"
    local override="${2:-}"

    # Resolve frequency:duration or freq1:dur1,freq2:dur2
    local spec=""
    if [ -n "$override" ]; then
        spec="$override"
    else
        case "$event" in
            complete) spec="1000:200,1200:300" ;;
            error)    spec="400:500"   ;;
            prompt)   spec="800:200"   ;;
            *)        spec="800:200"   ;;
        esac
    fi

    # Parse spec: "freq:dur" or "freq1:dur1,freq2:dur2"
    local tones=()
    IFS=',' read -ra tones <<< "$spec"
    local cmd=""
    for tone in "${tones[@]}"; do
        local freq="${tone%%:*}"
        local dur="${tone##*:}"
        if [ -n "$cmd" ]; then
            cmd="$cmd Start-Sleep -Milliseconds 80;"
        fi
        cmd="$cmd [System.Console]::Beep($freq,$dur);"
    done

    powershell.exe -NoProfile -Command "$cmd" &
}

# ── List available sounds ──────────────────────────────────────────────────────
list_sounds() {
    local os="$1"
    case "$os" in
        macos)
            echo "Available macOS system sounds (use name without .aiff):"
            echo ""
            for f in /System/Library/Sounds/*.aiff; do
                basename "$f" .aiff
            done | column
            echo ""
            echo "Example config (~/.ccbeep.json):"
            echo '  { "complete": "Sosumi", "error": "Funk" }'
            echo ""
            echo "Or use custom file:"
            echo '  { "complete": "/path/to/your/sound.wav" }'
            ;;
        linux)
            echo "Available Linux sounds:"
            for d in /usr/share/sounds/freedesktop/stereo \
                     /usr/share/sounds/ubuntu/stereo \
                     /usr/share/sounds/gnome/default/alerts; do
                if [ -d "$d" ]; then
                    echo ""
                    echo "  $d:"
                    ls "$d" 2>/dev/null | column || true
                fi
            done
            echo ""
            echo "Example config (~/.ccbeep.json):"
            echo '  { "complete": "complete", "error": "dialog-error" }'
            ;;
        windows)
            echo "Windows: use Beep frequency:duration format"
            echo ""
            echo "  Single tone:  \"800:200\""
            echo "  Multi tone:   \"1000:200,1200:300\""
            echo ""
            echo "Example config (~/.ccbeep.json):"
            echo '  { "complete": "1000:200,1200:300", "error": "400:500" }'
            ;;
    esac
}

# ── Parse stdin JSON for Stop hook reason ─────────────────────────────────────
detect_stop_reason() {
    local input
    input="$(cat 2>/dev/null || true)"

    if [ -z "$input" ]; then
        echo "complete"
        return
    fi

    if command -v python3 &>/dev/null; then
        local reason
        reason="$(echo "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('reason', 'complete'))
except:
    print('complete')
" 2>/dev/null || echo "complete")"
        echo "$reason"
        return
    fi

    if echo "$input" | grep -qiE '"reason"\s*:\s*"(error|interrupted|failed)"' ; then
        echo "error"
    else
        echo "complete"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    local event=""
    local sound_override=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --sound|-s)
                sound_override="$2"
                shift 2
                ;;
            *)
                if [ -z "$event" ]; then
                    event="$1"
                fi
                shift
                ;;
        esac
    done

    local os
    os="$(detect_os)"

    # Special: list available sounds
    if [ "$event" = "list" ]; then
        list_sounds "$os"
        exit 0
    fi

    # Handle 'stop' event: read stdin to figure out success vs error
    if [ "$event" = "stop" ]; then
        event="$(detect_stop_reason)"
    fi

    # Load config file if no CLI override
    if [ -z "$sound_override" ]; then
        sound_override="$(load_config "$event")"
    fi

    case "$os" in
        macos)   sound_macos   "$event" "$sound_override" ;;
        linux)   sound_linux   "$event" "$sound_override" ;;
        windows) sound_windows "$event" "$sound_override" ;;
        *)
            echo -e '\a'
            ;;
    esac
}

main "$@"
