# CCBeep

Sound notifications for [Claude Code](https://claude.ai/code) — know when Claude finishes a task or hits an error, without watching the terminal.

## Supported Platforms

| Platform | Sound Method | Fallback |
|----------|-------------|----------|
| **macOS** | `afplay` with built-in system sounds (Purr / Basso) | Terminal bell |
| **Linux** | `paplay` or `aplay` with freedesktop sound theme | Terminal bell |
| **Windows** | PowerShell `[System.Console]::Beep` or ccbee.ps1 | BEL character |

## Installation

### Method 1: One-command install

```bash
git clone https://github.com/your-username/CCBeepp.git && cd CCBeep && ./install.sh
```

The installer automatically detects paths, backs up your settings, and merges the hooks.

### Method 2: As a Claude Code plugin

Add the marketplace and enable the plugin in `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "ccbee": {
      "source": "github",
      "repo": "your-username/CCBeep"
    }
  },
  "enabledPlugins": {
    "ccbee@ccbee": true
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
          { "type": "command", "command": "/ABSOLUTE/PATH/TO/CCBeepp/ccbee.sh complete" }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "/ABSOLUTE/PATH/TO/CCBeepp/ccbee.sh stop" }
        ]
      }
    ]
  }
}
```

### Test sounds

```bash
./ccbee.sh complete     # Completion chime
./ccbee.sh error        # Warning sound
```

## Mute / Unmute

Temporarily silence notifications without uninstalling:

```bash
./mute.sh         # Mute permanently (until unmuted)
./mute.sh 2h      # Mute for 2 hours, auto-unmute
./mute.sh 30m     # Mute for 30 minutes
./mute.sh 1d      # Mute for 1 day

./unmute.sh       # Unmute immediately
```

Mute state is stored in `~/.ccbee_mute` — delete it manually to unmute from anywhere.

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
- Delete `"ccbee@ccbee"` from `enabledPlugins`
- Delete `"ccbee"` from `extraKnownMarketplaces`

### If installed manually

Remove the `hooks` block from `~/.claude/settings.json`.

Then delete the CCBeep directory.

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

Edit `ccbee.sh` to change the paths in `sound_linux()`.

### Windows

Edit `ccbee.ps1` and change the `Frequency` and `Duration` parameters in the `Play-Beep` calls.

## No Dependencies

Only system built-in tools: `afplay` (macOS), `paplay`/`aplay` (Linux), PowerShell (Windows).

---

## 中文说明

### CCBeep — Claude Code 声音通知工具

让 Claude Code 在任务完成或中断时自动发出提示音，不用盯着终端也能知道状态变化。

### 安装方式

**方式一：一键安装**
```bash
git clone https://github.com/your-username/CCBeepp.git && cd CCBeep && ./install.sh
```

**方式二：作为插件安装**

在 `~/.claude/settings.json` 中添加：
```json
{
  "extraKnownMarketplaces": {
    "ccbee": { "source": "github", "repo": "your-username/CCBeep" }
  },
  "enabledPlugins": {
    "ccbee@ccbee": true
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
