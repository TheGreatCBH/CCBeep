#!/usr/bin/env bash
# CCBee - Sound notifications for Claude Code events
# https://github.com/your-username/CCBeep
#
# Usage:
#   ccbee.sh prompt          Play prompt sound (waiting for input)
#   ccbee.sh complete        Play completion sound
#   ccbee.sh error           Play error/interrupt sound
#   ccbee.sh stop            Read stdin JSON from Claude Code Stop hook,
#                            auto-detect error vs complete
#
# Hook integration (settings.json):
#   "UserPromptSubmit": [{"matcher": "", "hooks": [{"type": "command", "command": ".../ccbee.sh prompt"}]}]
#   "Notification":     [{"matcher": "", "hooks": [{"type": "command", "command": ".../ccbee.sh complete"}]}]
#   "Stop":             [{"matcher": "", "hooks": [{"type": "command", "command": ".../ccbee.sh stop"}]}]
set -euo pipefail

# ── OS detection ──────────────────────────────────────────────────────────────
detect_os() {
    case "$(uname -s)" in
        Darwin)  echo "macos"   ;;
        Linux)   echo "linux"   ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *)       echo "unknown" ;;
    esac
}

# ── macOS: use afplay with built-in system sounds ─────────────────────────────
sound_macos() {
    local name="$1"
    local sound_file
    case "$name" in
        prompt)   sound_file="/System/Library/Sounds/Glass.aiff"   ;;
        complete) sound_file="/System/Library/Sounds/Purr.aiff"    ;;
        error)    sound_file="/System/Library/Sounds/Basso.aiff"   ;;
        *)        sound_file="/System/Library/Sounds/Glass.aiff"   ;;
    esac
    if [ -f "$sound_file" ]; then
        afplay "$sound_file" &
    else
        echo -e '\a'
    fi
}

# ── Linux: prefer paplay (PulseAudio), fallback to terminal bell ──────────────
sound_linux() {
    local name="$1"
    # freedesktop sound theme paths (most distros)
    local sound_dir="/usr/share/sounds/freedesktop/stereo"
    local sound_file
    case "$name" in
        prompt)   sound_file="$sound_dir/message.oga"        ;;
        complete) sound_file="$sound_dir/complete.oga"       ;;
        error)    sound_file="$sound_dir/dialog-error.oga"   ;;
        *)        sound_file="$sound_dir/message.oga"        ;;
    esac

    if command -v paplay &>/dev/null && [ -f "$sound_file" ]; then
        paplay "$sound_file" &
    elif command -v aplay &>/dev/null && [ -f "$sound_file" ]; then
        aplay "$sound_file" &>/dev/null &
    else
        echo -e '\a'
    fi
}

# ── Windows: PowerShell System.Console.Beep ───────────────────────────────────
sound_windows() {
    local name="$1"
    local freq dur
    case "$name" in
        prompt)   freq=800;  dur=200 ;;
        complete)
            # Two ascending tones
            powershell.exe -NoProfile -Command "[System.Console]::Beep(1000,200); Start-Sleep -Milliseconds 80; [System.Console]::Beep(1200,300)" &
            return
            ;;
        error)    freq=400;  dur=500 ;;
        *)        freq=800;  dur=200 ;;
    esac
    powershell.exe -NoProfile -Command "[System.Console]::Beep($freq,$dur)" &
}

# ── Parse stdin JSON for Stop hook reason ─────────────────────────────────────
# Claude Code Stop hook writes JSON to stdin, e.g.:
#   {"type":"stop","reason":"completed"}
#   {"type":"stop","reason":"error"}
#   {"type":"stop","reason":"interrupted"}
detect_stop_reason() {
    local input
    input="$(cat 2>/dev/null || true)"

    if [ -z "$input" ]; then
        echo "complete"
        return
    fi

    # Try python3 for reliable JSON parsing
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

    # Fallback: grep for error/interrupted keywords
    if echo "$input" | grep -qiE '"reason"\s*:\s*"(error|interrupted|failed)"' ; then
        echo "error"
    else
        echo "complete"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    local event="${1:-prompt}"
    local os
    os="$(detect_os)"

    # Handle 'stop' event: read stdin to figure out success vs error
    if [ "$event" = "stop" ]; then
        event="$(detect_stop_reason)"
    fi

    case "$os" in
        macos)   sound_macos   "$event" ;;
        linux)   sound_linux   "$event" ;;
        windows) sound_windows "$event" ;;
        *)
            # Last resort: terminal bell
            echo -e '\a'
            ;;
    esac
}

main "$@"
