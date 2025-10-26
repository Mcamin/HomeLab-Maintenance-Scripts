#!/bin/bash
#
# Disable Proxmox "No valid subscription" popup banner
# Works with Proxmox VE 7.x / 8.x / 9.x
#
# Author: ChatGPT (based on community scripts)
# License: MIT
#

set -e

TARGET="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"
BACKUP="${TARGET}.bak.$(date +%F_%H-%M-%S)"

echo "🔍 Checking Proxmox subscription popup file..."
if [ ! -f "$TARGET" ]; then
    echo "❌ File not found: $TARGET"
    echo "This script may not be compatible with your version of Proxmox."
    exit 1
fi

# Backup the original file (only once per run)
echo "📦 Backing up original file to: $BACKUP"
cp "$TARGET" "$BACKUP"

# Patch the file safely
if grep -q "data.status !== 'Active'" "$TARGET"; then
    echo "🧩 Applying patch..."
    sed -i "s/data.status !== 'Active'/false/" "$TARGET"
    echo "✅ Popup check disabled successfully."
else
    echo "ℹ️  The patch line was not found — maybe already patched or updated version."
fi

# Restart web service
echo "🔁 Restarting Proxmox web interface..."
systemctl restart pveproxy

echo "🎉 Done. Refresh your browser (Ctrl + Shift + R) to clear cache."
echo "📁 A backup of the original file is at: $BACKUP"
