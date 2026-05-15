# CCBee

Sound notifications for [Claude Code](https://claude.ai/code) — know when Claude finishes a task or hits an error, without watching the terminal.

## Supported Platforms

| Platform | Sound Method | Fallback |
|----------|-------------|----------|
| **macOS** | `afplay` with built-in system sounds (Purr / Basso) | Terminal bell |
| **Linux** | `paplay` or `aplay` with freedesktop sound theme | Terminal bell |
| **Windows** | PowerShell `[System.Console]::Beep` or ccbee.ps1 | BEL character |

## Quick Start

### One-command install

```bash
git clone https://github.com/your-username/CCBeep.git && cd CCBee && ./install.sh
```

That's it. The installer automatically:
- Detects the CCBee directory
- Backs up your existing `~/.claude/settings.json`
- Merges the hooks into your settings

### Manual install

If you prefer to configure manually, add the following to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/ABSOLUTE/PATH/TO/CCBeep/ccbee.sh complete"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/ABSOLUTE/PATH/TO/CCBeep/ccbee.sh stop"
          }
        ]
      }
    ]
  }
}
```

Replace `/ABSOLUTE/PATH/TO/CCBeep` with the actual path. If you already have settings, merge only the `"hooks"` block.

### Windows (PowerShell)

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -File \"C:\\path\\to\\CCBeep\\ccbee.ps1\" -Event complete",
            "shell": "powershell"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -File \"C:\\path\\to\\CCBeep\\ccbee.ps1\" -Event stop",
            "shell": "powershell"
          }
        ]
      }
    ]
  }
}
```

You can also run `ccbee.sh` under Git Bash or WSL on Windows.

### Test sounds

```bash
./ccbee.sh complete     # Completion chime
./ccbee.sh error        # Warning sound
```

## Event Types

| Event | Hook | Sound | When |
|-------|------|-------|------|
| **Task complete** | `Notification` | Pleasant two-tone chime | Task finishes successfully |
| **Task stop (success)** | `Stop` | Completion chime | Agent stops normally |
| **Task stop (error)** | `Stop` | Low warning tone | Task interrupted, failed, or cancelled |

The `Stop` hook receives JSON from Claude Code on stdin. CCBee reads the `reason` field and picks the right sound automatically (`"completed"` → complete, `"error"` / `"interrupted"` → error).

## Uninstall

```bash
# Restore from the backup created by install.sh
cp ~/.claude/settings.json.backup.* ~/.claude/settings.json
```

Or manually remove the `hooks` block from `~/.claude/settings.json`.

## Customizing Sounds

### macOS

Use any built-in system sound from `/System/Library/Sounds/`:

```
Basso  Blow  Bottle  Frog  Funk  Glass  Hero
Morse  Ping  Pop  Purr  Sosumi  Submarine  Tink
```

Edit `ccbee.sh` and change the sound names in the `sound_macos()` function.

### Linux

Available sounds depend on your sound theme. Common paths:

- `/usr/share/sounds/freedesktop/stereo/`
- `/usr/share/sounds/ubuntu/stereo/`
- `/usr/share/sounds/gnome/default/alerts/`

Edit `ccbee.sh` to change the paths in `sound_linux()`. Falls back to `aplay` (ALSA) or terminal bell if PulseAudio is unavailable.

### Windows

Edit `ccbee.ps1` and change the `Frequency` and `Duration` parameters in the `Play-Beep` calls.

## No Dependencies

CCBee uses only system built-in tools:

- **macOS**: `afplay` (pre-installed)
- **Linux**: `paplay` (PulseAudio, default on most distros) or `aplay` (ALSA)
- **Windows**: PowerShell (pre-installed)

No `pip install`, no `brew install`, no third-party packages.

---

## 中文说明

### CCBee — Claude Code 声音通知工具

让 Claude Code 在任务完成或中断时自动发出提示音，你不用盯着终端也能知道状态变化。

### 一键安装

```bash
git clone https://github.com/your-username/CCBeep.git && cd CCBee && ./install.sh
```

安装脚本会自动：
- 检测 CCBee 目录
- 备份现有 `~/.claude/settings.json`
- 将 hooks 合并到配置文件中

### 事件说明

| 事件 | Hook | 声音 | 触发时机 |
|------|------|------|----------|
| 任务完成 | `Notification` | 悦耳双音阶 | 任务成功完成 |
| 正常停止 | `Stop` | 完成音 | Agent 正常结束 |
| 运行中断 | `Stop` | 低沉警告音 | 任务出错或中断 |

### 卸载

```bash
cp ~/.claude/settings.json.backup.* ~/.claude/settings.json
```

### 自定义声音

编辑 `ccbee.sh` 中的声音名称即可。macOS 系统自带的声音文件在 `/System/Library/Sounds/` 目录下，Linux 在 `/usr/share/sounds/` 下。

### 零依赖

只使用系统自带工具，不需要安装任何第三方库。

## License

MIT — see [LICENSE](LICENSE).
