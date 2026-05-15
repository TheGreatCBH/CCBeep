# CCBeep

Sound notifications for [Claude Code](https://claude.ai/code) — know when Claude finishes a task or hits an error, without watching the terminal.

## Supported Platforms

| Platform | Sound Method | Fallback |
|----------|-------------|----------|
| **macOS** | `afplay` with built-in system sounds (Purr / Basso) | Terminal bell |
| **Linux** | `paplay` or `aplay` with freedesktop sound theme | Terminal bell |
| **Windows** | PowerShell `[System.Console]::Beep` or ccbeep.ps1 | BEL character |

## Installation

### Method 1: One-command install

```bash
git clone https://github.com/your-username/CCBeep.git && cd CCBeep && ./install.sh
```

The installer automatically detects paths, backs up your settings, and merges the hooks.

### Method 2: As a Claude Code plugin

Add the marketplace and enable the plugin in `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "ccbeep": {
      "source": "github",
      "repo": "your-username/CCBeep"
    }
  },
  "enabledPlugins": {
    "ccbeep@ccbeep": true
  }
}
```

Then restart Claude Code. The plugin's hooks are automatically loaded — no path configuration needed.

### Method 3: Manual hook configuration

Add directly to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "/ABSOLUTE/PATH/TO/CCBeep/ccbeep.sh complete" }
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
./ccbeep.sh complete     # Completion chime
./ccbeep.sh error        # Warning sound
./ccbeep.sh list         # List available sounds for your OS
```

## Customizing Sounds

No need to edit the script. Three ways to customize:

### 0. Interactive configurator (easiest)

```bash
# One command:
./configure.sh --complete Sosumi --error Funk
./configure.sh --complete 12 --error 5        # by number
./configure.sh --list                         # see options

# Or interactive (terminal only):
./configure.sh
```

### 1. Persistent config (recommended)

### 1. Persistent config (recommended)

Create `~/.ccbeep.json`:

```json
{
  "complete": "Sosumi",
  "error": "Funk"
}
```

See `ccbeep.config.example.json` for OS-specific examples.

### 2. One-off override

```bash
./ccbeep.sh complete --sound Ping
./ccbeep.sh error   --sound /path/to/custom.wav
```

### 3. Discover available sounds

```bash
./ccbeep.sh list
```

This shows all system sounds available on your OS.

### macOS

Built-in sounds in `/System/Library/Sounds/`:

```
Basso  Blow  Bottle  Frog  Funk  Glass  Hero
Morse  Ping  Pop  Purr  Sosumi  Submarine  Tink
```

Use the name without `.aiff` extension, or a full file path.

### Linux

Sound names are resolved against freedesktop/ubuntu/gnome sound theme directories. Use the filename (with or without `.oga`), or a full path.

### Windows

Use Beep frequency:duration format: `"800:200"` for single tone, `"1000:200,1200:300"` for multi-tone.

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

## Event Types

| Event | Hook | Sound | When |
|-------|------|-------|------|
| **Task complete** | `Notification` | Pleasant two-tone chime | Task finishes successfully |
| **Task stop (success)** | `Stop` | Completion chime | Agent stops normally |
| **Task stop (error)** | `Stop` | Low warning tone | Task interrupted, failed, or cancelled |

The `Stop` hook receives JSON on stdin. CCBeep reads the `reason` field and picks the right sound automatically.

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

Remove the `hooks` block from `~/.claude/settings.json`.

Then delete the CCBeep directory.

## No Dependencies

Only system built-in tools: `afplay` (macOS), `paplay`/`aplay` (Linux), PowerShell (Windows).

---

## 中文说明

### CCBeep — Claude Code 声音通知工具

让 Claude Code 在任务完成或中断时自动发出提示音，不用盯着终端也能知道状态变化。

### 安装方式

**方式一：一键安装**
```bash
git clone https://github.com/your-username/CCBeep.git && cd CCBeep && ./install.sh
```

**方式二：作为插件安装**

在 `~/.claude/settings.json` 中添加：
```json
{
  "extraKnownMarketplaces": {
    "ccbeep": { "source": "github", "repo": "your-username/CCBeep" }
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

不需要改脚本，三种方式：

**0. 配置器（最简单）**
```bash
# 一条命令：
./configure.sh --complete Sosumi --error Funk
./configure.sh --complete 12 --error 5        # 按编号
./configure.sh --list                         # 查看可选

# 或交互式（终端里运行）：
./configure.sh
```

**1. 配置文件（推荐）**

创建 `~/.ccbeep.json`：
```json
{ "complete": "Sosumi", "error": "Funk" }
```

**2. 命令行临时覆盖**
```bash
./ccbeep.sh complete --sound Ping
```

**3. 查看可用音效**
```bash
./ccbeep.sh list
```

参考 `ccbeep.config.example.json` 了解更多示例。

### 事件说明

| 事件 | Hook | 声音 | 触发时机 |
|------|------|------|----------|
| 任务完成 | `Notification` | 悦耳双音阶 | 任务成功完成 |
| 正常停止 | `Stop` | 完成音 | Agent 正常结束 |
| 运行中断 | `Stop` | 低沉警告音 | 任务出错或中断 |

### 卸载

- install.sh 安装：`cp ~/.claude/settings.json.backup.* ~/.claude/settings.json`
- 插件安装：从 `enabledPlugins` 和 `extraKnownMarketplaces` 中移除对应项
- 手动安装：从 settings.json 中删除 `hooks` 块

## License

MIT — see [LICENSE](LICENSE).
