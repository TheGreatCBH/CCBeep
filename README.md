# CCBee

Sound notifications for [Claude Code](https://claude.ai/code) — know what Claude is doing without watching the terminal.

When Claude Code is waiting for your input, finishes a task, or hits an error, CCBee plays a distinct sound so you can stay focused on other work.

## Supported Platforms

| Platform | Sound Method | Fallback |
|----------|-------------|----------|
| **macOS** | `afplay` with built-in system sounds (Glass / Purr / Basso) | Terminal bell |
| **Linux** | `paplay` or `aplay` with freedesktop sound theme | Terminal bell |
| **Windows** | PowerShell `[System.Console]::Beep` or ccbee.ps1 | BEL character |

## Quick Start

### 1. Clone & install

```bash
git clone https://github.com/your-username/CCBeep.git
cd CCBee
chmod +x ccbee.sh
```

### 2. Test sounds

```bash
./ccbee.sh prompt       # Gentle notification
./ccbee.sh complete     # Completion chime
./ccbee.sh error        # Warning sound
```

### 3. Configure hooks

Add the following to your Claude Code settings:

**User-level** (`~/.claude/settings.json`):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/ABSOLUTE/PATH/TO/CCBeep/ccbee.sh prompt"
          }
        ]
      }
    ],
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

Replace `/ABSOLUTE/PATH/TO/CCBeep` with the actual path (e.g., `/Users/you/projects/CCBeep`).

If you already have other settings, merge only the `"hooks"` block — do not replace your entire file. See `settings.example.json` for a complete reference.

### Windows (PowerShell)

On Windows with PowerShell, use the `.ps1` script with the `powershell` shell type:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -File \"C:\\path\\to\\CCBeep\\ccbee.ps1\" -Event prompt",
            "shell": "powershell"
          }
        ]
      }
    ],
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

## Event Types

| Event | Hook | Sound | When |
|-------|------|-------|------|
| **Prompt** | `UserPromptSubmit` | Short notification ding | User submits a prompt, system acknowledges |
| **Complete** | `Notification` | Pleasant two-tone chime | Task finishes successfully |
| **Stop (error)** | `Stop` | Low warning tone | Task interrupted, failed, or cancelled |
| **Stop (success)** | `Stop` | Completion chime | Task ends normally |

The `Stop` hook receives JSON from Claude Code on stdin. CCBee reads this JSON and automatically picks the right sound based on the `reason` field (`"completed"` → complete, `"error"` / `"interrupted"` → error).

## Customizing Sounds

### macOS

Use any built-in system sound from `/System/Library/Sounds/`:

```
Basso  Blow  Bottle  Frog  Funk  Glass  Hero
Morse  Ping  Pop  Purr  Sosumi  Submarine  Tink
```

Edit `ccbee.sh` and change the sound names in the `sound_macos()` function, or pass a custom argument:

```bash
./ccbee.sh custom /System/Library/Sounds/Sosumi.aiff
```

### Linux

Available sounds depend on your sound theme. Common paths:

- `/usr/share/sounds/freedesktop/stereo/`
- `/usr/share/sounds/ubuntu/stereo/`
- `/usr/share/sounds/gnome/default/alerts/`

Edit `ccbee.sh` to change the paths in `sound_linux()`, or install additional sound themes.

If PulseAudio is not available, the script falls back to `aplay` (ALSA) or terminal bell (`echo -e '\a'`).

### Windows

Edit `ccbee.ps1` and change the `Frequency` and `Duration` parameters in the `Play-Beep` calls. Higher frequency = higher pitch, higher duration = longer beep.

## No Dependencies

CCBee uses only system built-in tools:

- **macOS**: `afplay` (pre-installed)
- **Linux**: `paplay` (PulseAudio, installed by default on most distros) or `aplay` (ALSA)
- **Windows**: PowerShell (pre-installed) or `echo -e '\a'` under WSL/Git Bash

No `pip install`, no `brew install`, no third-party packages.

---

## 中文说明

### CCBee — Claude Code 声音通知工具

让 Claude Code 在等待输入、任务完成或中断时自动发出提示音，你不用盯着终端也能知道状态变化。

### 快速开始

```bash
git clone https://github.com/your-username/CCBeep.git
cd CCBee
chmod +x ccbee.sh
```

### 测试声音

```bash
./ccbee.sh prompt       # 提示音
./ccbee.sh complete     # 完成音
./ccbee.sh error        # 错误/警告音
```

### 配置 hooks

在 `~/.claude/settings.json` 中添加（把 `/ABSOLUTE/PATH/TO/CCBeep` 替换为实际路径）：

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "/ABSOLUTE/PATH/TO/CCBeep/ccbee.sh prompt" }] }
    ],
    "Notification": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "/ABSOLUTE/PATH/TO/CCBeep/ccbee.sh complete" }] }
    ],
    "Stop": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "/ABSOLUTE/PATH/TO/CCBeep/ccbee.sh stop" }] }
    ]
  }
}
```

### 事件说明

| 事件 | Hook | 声音 | 触发时机 |
|------|------|------|----------|
| 等待输入 | `UserPromptSubmit` | 短促提示音 | 用户提交 prompt 时 |
| 任务完成 | `Notification` | 悦耳双音阶 | 任务成功完成 |
| 运行中断 | `Stop` | 低沉警告音 | 任务出错或中断 |

### 自定义声音

编辑 `ccbee.sh` 中的声音名称即可。macOS 系统自带的声音文件在 `/System/Library/Sounds/` 目录下，Linux 在 `/usr/share/sounds/` 下。

### 零依赖

只使用系统自带工具，不需要安装任何第三方库。

## License

MIT — see [LICENSE](LICENSE).
