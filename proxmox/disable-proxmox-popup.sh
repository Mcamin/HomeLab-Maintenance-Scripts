#!/bin/bash
#
# Disable Proxmox "No valid subscription" popup (universal for 7.x–9.x)
#

set -e

TARGET="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"
BACKUP="${TARGET}.bak.$(date +%F_%H-%M-%S)"

echo "📦 Backing up -> $BACKUP"
cp "$TARGET" "$BACKUP"

echo "🧩 Applying multi-version patch..."
sed -i "s/data.status !== 'Active'/false/" "$TARGET" || true
sed -i "s/res.status !== 'Active'/false/" "$TARGET" || true
sed -i "s/res.data.status !== 'Active'/false/" "$TARGET" || true
sed -i "s/res.data.status.toLowerCase() !== 'active'/false/" "$TARGET" || true
sed -i "s/status.toLowerCase() !== 'active'/false/" "$TARGET" || true

echo "🔁 Restarting Proxmox web service..."
systemctl restart pveproxy

echo "✅ Popup disabled! Hard-refresh your browser (Ctrl + Shift + R)."
echo "📁 Backup: $BACKUP"
