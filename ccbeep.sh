#!/usr/bin/env bash
# CCBeep - Sound notifications for Claude Code events
# https://github.com/TheGreatCBH/CCBeep
#
# Usage:
#   ccbeep.sh <event>                Play sound (complete / stop / prompt / ...)
#   ccbeep.sh <event> --sound Ping   Override sound for this call
#   ccbeep.sh list                   List available sounds for current OS
#
# Persistent customization: create ~/.ccbeep.json
#   { "complete": "Sosumi" }
#
# Priority: --sound flag > ~/.ccbeep.json > built-in default (Purr)
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
    val = config.get('${event}') or config.get('sound', '')
    if isinstance(val, str):
        print(val)
except:
    pass
" 2>/dev/null
}

# ── Terminal bell ──────────────────────────────────────────────────────────────
# Hook stdout is captured by Claude Code, so a plain `echo -e '\a'` never reaches
# the terminal. Walk up the process tree to the first ancestor that owns a tty
# (normally the claude process) and write BEL there. Over ssh / mosh / tmux the
# bell is forwarded to the local terminal, which plays its alert sound.
# The walk is bounded so a tty-less claude (IDE, `claude -p`) does not ring some
# unrelated terminal far up the tree; if nothing is found it stays silent rather
# than writing BEL into the captured hook output.
find_bell_tty() {
    local pid=$$ tty ppid hops=0
    while [ "$hops" -lt 6 ] && [[ "$pid" =~ ^[0-9]+$ ]] && [ "$pid" -gt 1 ]; do
        tty="" ppid=""
        read -r tty ppid < <(ps -o tty=,ppid= -p "$pid" 2>/dev/null || true) || true
        if [[ "$tty" =~ ^[A-Za-z0-9/]+$ ]] && [ -c "/dev/$tty" ] && [ -w "/dev/$tty" ]; then
            printf '%s' "/dev/$tty"
            return 0
        fi
        pid="$ppid"
        hops=$((hops + 1))
    done
    return 0
}

# The tty is resolved lazily, at most once, and always in the foreground: a
# backgrounded fallback (player failed after this script exited) must not walk
# the tree from a PID that may already be gone or reused.
BELL_TTY="" BELL_TTY_RESOLVED=0
resolve_bell_tty() {
    if [ "$BELL_TTY_RESOLVED" -eq 0 ]; then
        BELL_TTY="$(find_bell_tty)"
        BELL_TTY_RESOLVED=1
    fi
}
ring_bell() {
    bell_disabled && return 0
    resolve_bell_tty
    if [ -n "$BELL_TTY" ]; then
        printf '\a' > "$BELL_TTY" 2>/dev/null || true
    fi
    return 0
}

# Play a sound in the background; if the player fails, ring the bell instead.
# Output is detached so the hook's pipes close immediately (PermissionRequest
# is synchronous).
play_or_bell() {
    if bell_disabled; then
        "$@" >/dev/null 2>&1 &
        return 0
    fi
    resolve_bell_tty
    { "$@" || ring_bell; } >/dev/null 2>&1 &
}

# CCBEEP_MODE=local means "local player only": no bell, not even as a fallback.
bell_disabled() {
    [ "$(printf '%s' "${CCBEEP_MODE:-}" | tr '[:upper:]' '[:lower:]')" = local ]
}

# Remote mode: play the sound on the terminal you are looking at instead of the
# machine Claude Code runs on. Used when Claude Code runs on a server you reach
# via ssh / mosh / tmux, where afplay / paplay would play on the server.
#   CCBEEP_MODE=bell   always use the terminal bell
#   CCBEEP_MODE=local  always use the local sound player (previous behaviour)
#   unset              auto: bell when in an SSH session (even with X forwarding,
#                      audio would still play on the server). Inside tmux the
#                      SSH variables can be stale or missing; set the mode
#                      explicitly if auto picks wrong.
# If bell mode finds no terminal (IDE, `claude -p`), the local player is used.
# Players that fail at runtime (e.g. paplay with no sound server) also fall back
# to the bell. That rescues mosh/tmux sessions without SSH variables only when the
# server has no working audio; otherwise set CCBEEP_MODE=bell.
use_bell() {
    local mode
    mode="$(printf '%s' "${CCBEEP_MODE:-auto}" | tr '[:upper:]' '[:lower:]')"
    case "$mode" in
        bell)  return 0 ;;
        local) return 1 ;;
        auto|"") ;;
        *) echo "ccbeep: unknown CCBEEP_MODE='${CCBEEP_MODE}', expected bell|local; using auto" >&2 ;;
    esac
    [ -n "${SSH_CONNECTION:-}${SSH_TTY:-}" ]
}

# ── macOS ──────────────────────────────────────────────────────────────────────
sound_macos() {
    local sound_name="${1:-Purr}"

    if [[ "$sound_name" == */* ]]; then
        # Custom file path
        if [ -f "$sound_name" ]; then
            play_or_bell afplay "$sound_name"
        else
            ring_bell
        fi
    else
        # System sound name
        local sound_file="/System/Library/Sounds/${sound_name}.aiff"
        if [ -f "$sound_file" ]; then
            play_or_bell afplay "$sound_file"
        else
            ring_bell
        fi
    fi
}

# ── Linux ──────────────────────────────────────────────────────────────────────
sound_linux() {
    local override="${1:-}"

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
        sound_file="/usr/share/sounds/freedesktop/stereo/complete.oga"
    fi

    if [ -f "$sound_file" ]; then
        if command -v paplay &>/dev/null; then
            play_or_bell paplay "$sound_file"
        elif command -v aplay &>/dev/null; then
            play_or_bell aplay "$sound_file"
        else
            ring_bell
        fi
    else
        ring_bell
    fi
}

# ── Windows ────────────────────────────────────────────────────────────────────
sound_windows() {
    local spec="${1:-1000:200,1200:300}"

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

    # Bell mode needs a Unix ps; Windows keeps its PowerShell beep.
    if { [ "$os" = macos ] || [ "$os" = linux ]; } && use_bell; then
        resolve_bell_tty
        if [ -n "$BELL_TTY" ]; then
            ring_bell
            exit 0
        fi
    fi

    # Load config file if no CLI override
    if [ -z "$sound_override" ]; then
        sound_override="$(load_config "$event")"
    fi

    case "$os" in
        macos)   sound_macos   "$sound_override" ;;
        linux)   sound_linux   "$sound_override" ;;
        windows) sound_windows "$sound_override" ;;
        *)
            ring_bell
            ;;
    esac
}

main "$@"
