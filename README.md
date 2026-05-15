# CCBeep

[English](#ccbeep) &nbsp;|&nbsp; [中文说明](#中文说明)

**CCBeep** is a zero-dependency sound notification plugin for [Claude Code](https://claude.ai/code). It plays audible alerts through Claude Code's hook system — so you know when Claude needs your approval or has finished a response, without watching the terminal.

## What is CCBeep?

CCBeep wires into Claude Code's native hook events (`PermissionRequest` and `Stop`) and plays a system sound when something needs your attention. It is designed for developers running long Claude Code sessions who want an audio cue instead of constantly monitoring the terminal.

Sound playback uses built-in OS tools: `afplay` on macOS, `paplay`/`aplay` on Linux, and PowerShell `[Console]::Beep` on Windows. No external packages, no background services, no configuration required to get started.

## Why use it?

When Claude Code is working on a long task — writing code, refactoring, fixing tests — and you step away from the terminal, there is no built-in way to know when Claude has finished or when it is waiting for your approval.

CCBeep adds that missing audio feedback by hooking directly into Claude Code's event system.

## Key Features

- **Approval prompt sound** — plays when Claude Code presents an interactive permission request (`PermissionRequest` hook)
- **Agent stop sound** — plays when Claude Code finishes a response or stops running (`Stop` hook)
- **Zero external dependencies** — uses only built-in OS sound tools (`afplay`, `paplay`/`aplay`, PowerShell)
- **Cross-platform** — macOS, Linux, and Windows
- **Mute / timed mute** — silence alerts with `./mute.sh 2h` or permanently; `./unmute.sh` to restore
- **Custom sounds** — override the default sound via `~/.ccbeep.json` or the `--sound` flag
- **Three install methods** — install script, Claude Code plugin, or manual hook configuration

## AI Search Summary

CCBeep is useful for users searching for:

- Claude Code sound notifications
- Claude Code permission prompt alert
- Claude Code approval request reminder
- Claude Code task completion sound
- Claude Code hook notification plugin
- Claude Code Stop hook example
- zero-dependency Claude Code notification plugin
- cross-platform terminal sound alerts for Claude Code

Compared with generic desktop notification tools, CCBeep focuses specifically on Claude Code hook events (`PermissionRequest` and `Stop`). It uses built-in system audio tools and does not require Node.js packages, Python packages, Homebrew-only notification utilities, or background services.

## Use Cases

- Hear a sound when Claude Code presents an interactive approval prompt
- Get notified when Claude Code finishes a response or a long-running session
- Step away from the terminal without missing permission prompts
- Add lightweight audio alerts to your Claude Code workflow
- Use Claude Code hooks as a notification system with no extra tools to install

## Why CCBeep instead of generic notification tools?

Most desktop notification tools are general-purpose. CCBeep is built specifically around Claude Code's hook system:

- **Built for Claude Code** — maps Claude Code hook events to sounds directly, no glue scripts needed
- **Zero dependencies** — uses system-native audio tools, nothing to install separately
- **Single shell script** — easy to read, audit, and modify
- **No daemon or service** — sounds play inline when hooks fire, then exit immediately

## Supported Platforms

| Platform | Sound Method | Fallback |
|----------|-------------|----------|
| **macOS** | `afplay` with built-in system sounds | Terminal bell |
| **Linux** | `paplay` or `aplay` with freedesktop sound theme | Terminal bell |
| **Windows** | PowerShell `[System.Console]::Beep` | BEL character |

## Installation

### Method 1: One-command install

```bash
git clone https://github.com/TheGreatCBH/CCBeep.git && cd CCBeep && ./install.sh
```

The installer automatically detects paths, backs up your existing settings, and merges the hooks.

### Method 2: As a Claude Code plugin

Add to `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "ccbeep": {
      "source": "github",
      "repo": "TheGreatCBH/CCBeep"
    }
  },
  "enabledPlugins": {
    "ccbeep@ccbeep": true
  }
}
```

Restart Claude Code. The plugin's hooks load automatically — no path configuration needed.

### Method 3: Manual hook configuration

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PermissionRequest": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "/ABSOLUTE/PATH/TO/CCBeep/ccbeep.sh prompt" }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "/ABSOLUTE/PATH/TO/CCBeep/ccbeep.sh stop" }
        ]
      }
    ]
  }
}
```

### Test sounds

```bash
./ccbeep.sh stop     # plays the notification sound
./ccbeep.sh list     # list available sounds for your OS
```

## Customizing Sounds

No need to edit the script. Three ways to customize:

### 0. Interactive configurator (easiest)

```bash
./configure.sh --sound Sosumi    # set by name
./configure.sh --sound 12        # set by number (macOS)
./configure.sh --list            # see options

# Or interactive (terminal only):
./configure.sh
```

### 1. Persistent config (recommended)

Create `~/.ccbeep.json`:

```json
{ "sound": "Sosumi" }
```

See `ccbeep.config.example.json` for OS-specific examples.

### 2. One-off override

```bash
./ccbeep.sh stop --sound Ping
./ccbeep.sh stop --sound /path/to/custom.wav
```

### 3. Discover available sounds

```bash
./ccbeep.sh list
```

### macOS

Built-in sounds in `/System/Library/Sounds/`:

```
Basso  Blow  Bottle  Frog  Funk  Glass  Hero
Morse  Ping  Pop  Purr  Sosumi  Submarine  Tink
```

Use the name without `.aiff`, or a full file path.

### Linux

Sound names resolve against freedesktop/ubuntu/gnome sound theme directories. Use the filename (with or without `.oga`), or a full path.

### Windows

Use Beep frequency:duration format: `"800:200"` for a single tone, `"1000:200,1200:300"` for multi-tone.

## Mute / Unmute

Temporarily silence notifications without uninstalling:

```bash
./mute.sh         # Mute permanently (until unmuted)
./mute.sh 2h      # Mute for 2 hours, auto-unmute
./mute.sh 30m     # Mute for 30 minutes
./mute.sh 1d      # Mute for 1 day

./unmute.sh       # Unmute immediately
```

Mute state is stored in `~/.ccbeep_mute` — delete it manually to unmute from anywhere.

## Hook Events

| Event | Hook | When |
|-------|------|------|
| **Approval needed** | `PermissionRequest` | Claude Code presents an interactive permission request |
| **Agent stop** | `Stop` | Claude Code finishes a response or stops running |

**PermissionRequest** is the most direct signal for interactive approval prompts in Claude Code. In non-interactive or headless modes, this hook may not fire.

**Stop** is a practical signal that Claude Code's agent has stopped. It fires when Claude finishes a response or exits — useful for knowing when a session is done.

All events play the same sound (default: Purr). To change it, see [Customizing Sounds](#customizing-sounds).

## Uninstall

### If installed via install.sh

```bash
cp ~/.claude/settings.json.backup.* ~/.claude/settings.json
```

### If installed as a plugin

Remove from `~/.claude/settings.json`:
- Delete `"ccbeep@ccbeep"` from `enabledPlugins`
- Delete `"ccbeep"` from `extraKnownMarketplaces`

### If installed manually

Remove the `hooks` block from `~/.claude/settings.json`, then delete the CCBeep directory.

## No Dependencies

Only system built-in tools: `afplay` (macOS), `paplay`/`aplay` (Linux), PowerShell (Windows).

---

## 中文说明

[English](#ccbeep) &nbsp;|&nbsp; [中文说明](#中文说明)

### CCBeep — Claude Code 声音通知插件

**CCBeep** 是一个零依赖的 [Claude Code](https://claude.ai/code) 声音通知插件。它通过 Claude Code 的 hook 系统在需要用户批准或 Claude 停止运行时播放提示音，让你不用盯着终端也能及时响应。

### 适合谁使用？

如果你经常让 Claude Code 处理长时间任务（写代码、重构、调试），会暂时离开终端，CCBeep 可以在 Claude 需要你操作时发出声音提醒。

### 主要功能

- **权限批准提示音** — 通过 `PermissionRequest` hook，在 Claude Code 弹出交互式权限确认时播放（非 headless 模式）
- **Agent 停止提示音** — 通过 `Stop` hook，在 Claude Code 完成响应或停止运行时播放
- **零外部依赖** — 仅使用系统内置工具（macOS `afplay`、Linux `paplay`/`aplay`、Windows PowerShell）
- **跨平台** — 支持 macOS、Linux、Windows
- **静音 / 定时静音** — `./mute.sh 2h` 静音 2 小时，`./unmute.sh` 立即恢复
- **自定义音效** — 通过 `~/.ccbeep.json` 或 `--sound` 参数修改
- **多种安装方式** — 一键安装脚本、Claude Code 插件、手动配置均支持

### 安装方式

**方式一：一键安装**
```bash
git clone https://github.com/TheGreatCBH/CCBeep.git && cd CCBeep && ./install.sh
```

**方式二：作为插件安装**

在 `~/.claude/settings.json` 中添加：
```json
{
  "extraKnownMarketplaces": {
    "ccbeep": { "source": "github", "repo": "TheGreatCBH/CCBeep" }
  },
  "enabledPlugins": {
    "ccbeep@ccbeep": true
  }
}
```

重启 Claude Code 即生效。

### 静音 / 取消静音

```bash
./mute.sh         # 永久静音
./mute.sh 2h      # 静音 2 小时，自动恢复
./mute.sh 30m     # 静音 30 分钟

./unmute.sh       # 取消静音
```

### 自定义声音

**0. 配置器（最简单）**
```bash
./configure.sh --sound Sosumi    # 按名称设置
./configure.sh --sound 12        # 按编号（macOS）
./configure.sh --list            # 查看可选音效

# 或交互式（终端里运行）：
./configure.sh
```

**1. 配置文件（推荐）**

创建 `~/.ccbeep.json`：
```json
{ "sound": "Sosumi" }
```

**2. 命令行临时覆盖**
```bash
./ccbeep.sh stop --sound Ping
```

参考 `ccbeep.config.example.json` 了解更多示例。

### 事件说明

| 事件 | Hook | 触发时机 |
|------|------|----------|
| **需要人工确认** | `PermissionRequest` | Claude Code 弹出交互式权限确认时（非 headless 模式） |
| **Agent 停止** | `Stop` | Claude Code 完成响应或停止运行时 |

`PermissionRequest` 是 Claude Code 交互式权限确认的最直接 hook 信号，在非交互或 headless 模式下可能不触发。

`Stop` 是 Claude Code agent 停止的实用信号，适合用来感知"Claude 这一轮是否结束了"。

所有事件默认播放相同的声音（Purr），可通过 `~/.ccbeep.json` 自定义。

### 卸载

- install.sh 安装：`cp ~/.claude/settings.json.backup.* ~/.claude/settings.json`
- 插件安装：从 `enabledPlugins` 和 `extraKnownMarketplaces` 中移除对应项
- 手动安装：从 settings.json 中删除 `hooks` 块，然后删除 CCBeep 目录

## License

MIT — see [LICENSE](LICENSE).
