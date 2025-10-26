#!/bin/bash
# 🧩 Script: snapraid-job.sh
# 📘 Description:
#   Orchestrator script that triggers the SnapRAID sync job without waiting
#   for completion. The sync job itself handles starting the scrub process
#   and Telegram reporting once it completes successfully.
#
#   Each run generates its own timestamped log file for cleaner history.

# ========================
# 🔧 Configuration
# ========================
SYNC_SCRIPT="./snapraid-sync.sh"
LOG_DIR="./log/snapraid"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_FILE="$LOG_DIR/snapraid-job-${TIMESTAMP}.log"

# ========================
# 🗂️ Setup
# ========================
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=================================================="
echo "🕒 SnapRAID Sync Triggered: $(date '+%Y-%m-%d %H:%M:%S')"
echo "📦 Host: $(hostname)"
echo "👤 User: $(whoami)"
echo "📄 Log file: $LOG_FILE"
echo "-------------------------------------------"

# ========================
# ▶️ Trigger Sync Only
# ========================
if [ -x "$SYNC_SCRIPT" ]; then
  echo "🚀 Launching SnapRAID sync in background..."
  nohup bash "$SYNC_SCRIPT" >> "$LOG_FILE" 2>&1 &
  SYNC_PID=$!
  echo "✅ SnapRAID sync triggered (PID: $SYNC_PID)"
else
  echo "❌ Sync script not found or not executable: $SYNC_SCRIPT"
fi

echo "-------------------------------------------"
echo "🕒 SnapRAID sync started successfully — sync running in background."
echo "📄 Detailed logs: $LOG_FILE"
echo "=================================================="
exit 0
