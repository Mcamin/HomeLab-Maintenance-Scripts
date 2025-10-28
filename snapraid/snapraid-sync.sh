#!/bin/bash
# 🧩 Script: snapraid-sync.sh
# 📘 Description:
#   Runs SnapRAID sync safely, logs output, prevents concurrent runs,
#   and triggers the external `snapraid-scrub.sh` script after successful completion.
#   Sends Telegram notifications on success or failure.
#
# 📦 Exit Codes:
#   0 = Sync completed, scrub started successfully
#   1 = Sync already running
#   2 = Sync failed
#   3 = Scrub script not found or failed to start

# ========================
# 🔧 Configuration
# ========================
LOG_DIR="./logs/snapraid" # Change to your logs folder
TIMESTAMP=$(date '+%Y-%m-%d--%H-%M-%S')
LOG_FILE="$LOG_DIR/snapraid-sync-${TIMESTAMP}.log"
PID_FILE="./snapraid-sync.pid"

# Path to the separate scrub script (adjust if needed)
SCRUB_SCRIPT="./snapraid-scrub.sh" # Change to the script location

# Telegram configuration (expect environment vars set by playbook or system)
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID}"
TELEGRAM_API_URL="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"

# ========================
# 🗂️ Setup
# ========================
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

echo "=================================================="
echo "🕒 Started SnapRAID Sync: $START_TIME"
echo "📦 Host: $HOSTNAME"
echo "👤 User: $(whoami)"
echo "🔧 Working Directory: $(pwd)"
echo "📄 Log File: $LOG_FILE"
echo "-------------------------------------------"

# ========================
# 🚦 Prevent duplicate sync run
# ========================
if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null 2>&1; then
    echo "⚠️  SnapRAID sync already running (PID $(cat "$PID_FILE"))"
    echo "🕒 Checked at: $(date '+%Y-%m-%d %H:%M:%S')"
    exit 1
fi

# ========================
# ▶️ Run SnapRAID Sync
# ========================
echo "🚀 Starting SnapRAID sync..."
nohup snapraid sync >> "$LOG_FILE" 2>&1 &
PID=$!
echo "$PID" > "$PID_FILE"

wait $PID
SYNC_EXIT_CODE=$?

END_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Remove PID file when done
if [ -f "$PID_FILE" ]; then
    rm -f "$PID_FILE"
    echo "🗑️  Removed PID file: $PID_FILE"
fi

# ========================
# ❌ Handle sync failure
# ========================
if [ $SYNC_EXIT_CODE -ne 0 ]; then
    echo "❌ SnapRAID sync failed with exit code $SYNC_EXIT_CODE"
    echo "🕒 Time: $END_TIME"
    echo "=================================================="

    if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
        curl -s -X POST "$TELEGRAM_API_URL" \
            -H "Content-Type: application/json" \
            -d "{
                \"chat_id\": \"$TELEGRAM_CHAT_ID\",
                \"text\": \"❌ *SnapRAID sync FAILED* on _${HOSTNAME}_\\n🕒 Start: ${START_TIME}\\n🕓 End: ${END_TIME}\\n📄 Log: ${LOG_FILE}\\nExit code: ${SYNC_EXIT_CODE}\",
                \"parse_mode\": \"Markdown\"
            }" >/dev/null 2>&1
    fi

    exit 2
fi

# ========================
# ✅ Sync success
# ========================
echo "✅ SnapRAID sync completed successfully!"
echo "🕒 Time: $END_TIME"
echo "-------------------------------------------"

# Send Telegram notification for successful sync
if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
    curl -s -X POST "$TELEGRAM_API_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"chat_id\": \"$TELEGRAM_CHAT_ID\",
            \"text\": \"✅ *SnapRAID sync completed successfully* on _${HOSTNAME}_\\n🕒 Start: ${START_TIME}\\n🕓 End: ${END_TIME}\\n📄 Log: ${LOG_FILE}\\n🚀 Scrub will now start automatically.\",
            \"parse_mode\": \"Markdown\"
        }" >/dev/null 2>&1
fi

# ========================
# ▶️ Trigger Scrub Script
# ========================
if [ ! -x "$SCRUB_SCRIPT" ]; then
    echo "❌ Scrub script not found or not executable at: $SCRUB_SCRIPT"
    echo "Please check the path and permissions."
    echo "=================================================="
    exit 3
fi

echo "🚀 Running scrub script: $SCRUB_SCRIPT"
bash "$SCRUB_SCRIPT"

SCRUB_EXIT_CODE=$?
if [ $SCRUB_EXIT_CODE -ne 0 ]; then
    echo "⚠️  Scrub script exited with non-zero code: $SCRUB_EXIT_CODE"
    echo "Check scrub logs for details."
else
    echo "✅ Scrub script executed successfully!"
fi

echo "=================================================="
echo "🕒 Sync script finished at: $END_TIME"
echo "=================================================="
exit 0
