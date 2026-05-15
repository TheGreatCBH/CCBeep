#!/usr/bin/env bash
# CCBeep — One-command installer
# Usage: curl -fsSL <raw-url> | bash   OR   ./install.sh
set -euo pipefail

CCBEE_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "CCBeep installer"
echo "==============="
echo ""

# ── Check prerequisites ──────────────────────────────────────────────────────
if [ ! -f "$CCBEE_DIR/ccbeep.sh" ]; then
    echo -e "${RED}Error: ccbeep.sh not found in $CCBEE_DIR${NC}"
    echo "Please run this script from the CCBeep project directory."
    exit 1
fi

if [ ! -x "$CCBEE_DIR/ccbeep.sh" ]; then
    chmod +x "$CCBEE_DIR/ccbeep.sh"
fi

if ! command -v python3 &>/dev/null; then
    echo -e "${RED}Error: python3 is required but not found.${NC}"
    exit 1
fi

# ── Backup existing settings ──────────────────────────────────────────────────
if [ -f "$SETTINGS_FILE" ]; then
    BACKUP="$SETTINGS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$SETTINGS_FILE" "$BACKUP"
    echo -e "Backed up existing settings to ${YELLOW}$BACKUP${NC}"
fi

# ── Merge hooks into settings.json ────────────────────────────────────────────
python3 - "$CCBEE_DIR" "$SETTINGS_FILE" << 'PYEOF'
import sys, json, os

ccbeep_dir = sys.argv[1]
settings_file = sys.argv[2]

# Load or create settings
if os.path.exists(settings_file):
    with open(settings_file) as f:
        settings = json.load(f)
else:
    settings = {}

# Hooks to install
new_hooks = {
    "Notification": [
        {
            "matcher": "",
            "hooks": [
                {
                    "type": "command",
                    "command": f"{ccbeep_dir}/ccbeep.sh complete"
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
                    "command": f"{ccbeep_dir}/ccbeep.sh stop"
                }
            ]
        }
    ]
}

existing = settings.get("hooks", {})

# Check if already installed
already_installed = True
for hook_name, hook_entries in new_hooks.items():
    if hook_name not in existing:
        already_installed = False
        break
    for entry in hook_entries:
        if entry not in existing[hook_name]:
            already_installed = False
            break

if already_installed:
    print("\033[1;33mHooks already up to date — nothing to change.\033[0m")
    sys.exit(0)

# Merge: add new hooks, keep existing ones intact
for hook_name, hook_entries in new_hooks.items():
    existing[hook_name] = hook_entries

settings["hooks"] = existing

with open(settings_file, "w") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("\033[0;32mHooks installed successfully.\033[0m")
print(f"  Notification → task complete sound")
print(f"  Stop         → task stop (auto error/success)")
PYEOF

echo ""
echo -e "${GREEN}Done! CCBeep is now active.${NC}"
echo ""
echo "Test your setup:"
echo "  $CCBEE_DIR/ccbeep.sh complete"
echo ""
echo "Mute / unmute:"
echo "  $CCBEE_DIR/mute.sh 2h    Mute for 2 hours"
echo "  $CCBEE_DIR/unmute.sh     Unmute"
echo ""
echo "To uninstall, restore the backup:"
echo "  cp $BACKUP $SETTINGS_FILE"
echo ""
echo "To customize sounds, run:"
echo "  $CCBEE_DIR/configure.sh"
