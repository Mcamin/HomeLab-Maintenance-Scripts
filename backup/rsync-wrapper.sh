#!/usr/bin/env bash
# 🧩 Script: copy.sh
# 📘 Description:
#   Performs a background rsync copy between two directories.
#   Includes robust logging, PID tracking, and Telegram notifications
#   when the process completes or fails.
#
# 📦 Behavior:
#   - Validates arguments
#   - Uses rsync to copy data with progress
#   - Logs output to ./logs/rsync/rsync_<timestamp>.log
#   - Saves PID file for tracking
#   - Sends Telegram message on success or failure
#
# 🧠 Example:
#   ./rsync-wrapper.sh /var/www/html /mnt/backup/html
#
# 🧱 Exit codes:
#   0 = success
#   1 = bad arguments
#   2 = rsync failure
# =====================================================================

set -euo pipefail

# ========================
# 🔧 Configuration
# ========================
LOG_DIR="./logs/rsync" # Change to your logs folder
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date '+%Y-%m-%d--%H-%M-%S')
LOG_FILE="$LOG_DIR/rsync_${TIMESTAMP}.log"
PID_FILE="./rsync_${TIMESTAMP}.pid"
HOSTNAME=$(hostname)

# Telegram configuration (from environment)
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
TELEGRAM_API_URL="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"

# ========================
# 🧩 Argument Validation
# ========================
if [[ $# -ne 2 ]]; then
    echo "❌ Usage: $0 <source> <destination>" >&2
    exit 1
fi

SRC="${1%/}/"
DST="${2%/}/"

# ========================
# 🏁 Start Info
# ========================
START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
echo "=================================================="
echo "🚀 Starting rsync copy"
echo "🕒 Start time: $START_TIME"
echo "📦 Host: $HOSTNAME"
echo "📁 Source: $SRC"
echo "📂 Destination: $DST"
echo "📄 Log File: $LOG_FILE"
echo "-------------------------------------------"

# ========================
# ▶️ Run rsync in background
# ========================
RSYNC_CMD="rsync -avh --progress \"$SRC\" \"$DST\""

(
    nohup bash -c "$RSYNC_CMD" > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
) &

PID=$(cat "$PID_FILE")
echo "🧩 PID file created: $PID_FILE (PID: $PID)"
echo "⏳ rsync process is now running in the background..."
echo "=================================================="

# ========================
# ⏱️ Wait for completion
# ========================
wait "$PID" 2>/dev/null || RSYNC_EXIT_CODE=$?
RSYNC_EXIT_CODE=${RSYNC_EXIT_CODE:-0}
END_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# ========================
# 🗑️ Cleanup
# ========================
if [ -f "$PID_FILE" ]; then
    rm -f "$PID_FILE"
    echo "🗑️ Removed PID file: $PID_FILE"
fi

# ========================
# ❌ Failure
# ========================
if [ $RSYNC_EXIT_CODE -ne 0 ]; then
    echo "❌ rsync failed with exit code $RSYNC_EXIT_CODE"
    echo "🕓 Finished at: $END_TIME"
    echo "=================================================="

    if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
        curl -s -X POST "$TELEGRAM_API_URL" \
            -H "Content-Type: application/json" \
            -d "{
                \"chat_id\": \"$TELEGRAM_CHAT_ID\",
                \"text\": \"❌ *Rsync FAILED* on _${HOSTNAME}_\\n🕒 Start: ${START_TIME}\\n🕓 End: ${END_TIME}\\n📄 Log: ${LOG_FILE}\\nExit code: ${RSYNC_EXIT_CODE}\",
                \"parse_mode\": \"Markdown\"
            }" >/dev/null 2>&1
    fi

    exit 2
fi

# ========================
# ✅ Success
# ========================
echo "✅ rsync completed successfully!"
echo "🕓 Finished at: $END_TIME"
echo "=================================================="

# Telegram notification — success
if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
    curl -s -X POST "$TELEGRAM_API_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"chat_id\": \"$TELEGRAM_CHAT_ID\",
            \"text\": \"✅ *Rsync completed successfully* on _${HOSTNAME}_\\n🕒 Start: ${START_TIME}\\n🕓 End: ${END_TIME}\\n📁 Source: ${SRC}\\n📂 Destination: ${DST}\\n📄 Log: ${LOG_FILE}\",
            \"parse_mode\": \"Markdown\"
        }" >/dev/null 2>&1
fi

exit 0
