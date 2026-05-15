# CCBeep v0.1.0 — Sound notifications for Claude Code hooks

CCBeep plays audible alerts through Claude Code's hook system, so you know when Claude needs your approval or has finished a response — without watching the terminal.

## Features

- **Approval prompt alert** via `PermissionRequest` hook — plays when Claude Code presents an interactive permission request
- **Agent stop alert** via `Stop` hook — plays when Claude Code finishes a response or stops running
- **Mute / timed mute** — `./mute.sh 2h` to silence for 2 hours, `./unmute.sh` to restore
- **Custom sounds** — override the default via `~/.ccbeep.json` (`{ "sound": "Sosumi" }`) or `--sound` flag
- **Single sound for all events** — keeps it simple; one audio cue means "something needs your attention"

## Supported Platforms

| Platform | Audio method |
|----------|-------------|
| macOS | `afplay` with built-in system sounds (default: Purr) |
| Linux | `paplay` or `aplay` with freedesktop sound theme |
| Windows | PowerShell `[System.Console]::Beep` |

## Installation

**One-command install:**
```bash
git clone https://github.com/TheGreatCBH/CCBeep.git && cd CCBeep && ./install.sh
```

**Claude Code plugin:** Add `ccbeep@ccbeep` to `enabledPlugins` and `TheGreatCBH/CCBeep` to `extraKnownMarketplaces` in `~/.claude/settings.json`, then restart Claude Code. See README for the full snippet.

**Manual:** Add `PermissionRequest` and `Stop` hook entries pointing to `ccbeep.sh` in `~/.claude/settings.json`.

## Notes on Claude Code hook behavior

- **PermissionRequest** fires for interactive approval prompts. In non-interactive or headless modes, this hook may not fire.
- **Stop** is a practical signal that Claude Code's agent has stopped. It fires when Claude finishes a response or exits — not a guarantee that a multi-step task fully completed successfully.
- The `Notification` hook (available in Claude Code) is intentionally not installed by default. It fires with a variable delay after a session ends, which caused duplicate sounds in testing. The `Stop` hook provides immediate feedback for the same event.

## Known limitations

- On Linux, sound playback requires `paplay` (PulseAudio) or `aplay` (ALSA). Falls back to terminal bell if neither is available.
- PermissionRequest is only relevant in interactive Claude Code sessions.
- Windows support uses PowerShell `Console::Beep`, which produces a system beep rather than a custom audio file. Custom `.wav` paths are not supported on Windows.

## Zero dependencies

No npm, no pip, no Homebrew packages. CCBeep uses only tools that ship with the OS.
