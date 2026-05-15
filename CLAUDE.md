# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 语言要求

所有回复必须使用中文。

## What this project is

CCBeep plays sound notifications for Claude Code events. The core script is `ccbeep.sh` (bash, macOS/Linux) and `ccbeep.ps1` (PowerShell, Windows). There are no build steps, no dependencies beyond system tools (`afplay`, `paplay`/`aplay`, PowerShell).

## Testing sounds

```bash
./ccbeep.sh complete          # Purr — task done
./ccbeep.sh error             # Basso — error/interrupted
./ccbeep.sh prompt            # Purr — approval dialog
./ccbeep.sh stop              # reads stdin JSON, auto-detects complete vs error
./ccbeep.sh list              # list available system sounds for current OS
```

To test with stdin JSON (simulating a hook call):
```bash
echo '{"reason":"error"}' | ./ccbeep.sh stop
```

Configure sounds interactively or non-interactively:
```bash
./configure.sh                          # interactive
./configure.sh --complete Sosumi --error Funk
./configure.sh --list                   # see available sounds
./configure.sh --test                   # play current config
./configure.sh --reset                  # restore defaults
```

## Architecture

### Event → hook → sound flow

```
Claude Code event
  → hook fires (settings.json or plugin hooks.json)
  → ccbeep.sh <event>
  → mute check (~/.ccbeep_mute)
  → OS detection
  → sound plays via afplay / paplay / PowerShell Beep
```

Three hooks are registered:
- **`PermissionRequest`** → `ccbeep.sh prompt`: fires exactly when a permission dialog appears, zero false positives.
- **`Notification`** → `ccbeep.sh complete`: plays completion chime.
- **`Stop`** → `ccbeep.sh stop`: reads stdin JSON `reason` field, plays `complete` or `error` sound.

### Key functions in `ccbeep.sh`

- `detect_stop_reason()`: reads Stop hook stdin JSON, returns `complete` or `error`.
- `load_config()`: reads `~/.ccbeep.json` for sound name overrides per event.
- `sound_macos/linux/windows()`: OS-specific sound dispatch; supports system sound names, full file paths, and (Windows) frequency:duration strings.

### Sound customization priority

CLI `--sound` flag → `~/.ccbeep.json` → built-in defaults (`Purr` / `Basso`)

### Mute state

Stored in `~/.ccbeep_mute`. Empty file = permanent mute. File containing a Unix timestamp = timed mute, auto-expires when `date +%s` exceeds it.

## Installation methods

**Via install.sh** — writes hooks with absolute paths into `~/.claude/settings.json`. Requires Claude Code restart to take effect.

**Via plugin** — `hooks/hooks.json` uses `${CLAUDE_PLUGIN_ROOT}` which Claude Code resolves at runtime. Plugin metadata is in `.claude-plugin/plugin.json` and `marketplace.json`.

After any hook changes, Claude Code must be fully restarted for them to apply.

## Adding a new event type

1. Add a sound case to `sound_macos()`, `sound_linux()`, `sound_windows()` in `ccbeep.sh`
2. Add a default sound to the `case "$event"` block in each OS function
3. Add the hook entry to `hooks/hooks.json`, `settings.example.json`, and `install.sh`
4. Update the events table in `README.md` (both English and Chinese sections)
