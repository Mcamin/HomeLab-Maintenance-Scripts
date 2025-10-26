#!/bin/bash
# 🧩 Script: snapraid-scrub.sh
# 📘 Description:
#   Runs a SnapRAID scrub (50%) safely, prevents duplicate runs,
#   logs detailed information, and sends Telegram notifications
#   on success or failure.
#
# 📦 Behavior:
#   - Checks if another scrub is already running
#   - Starts a new scrub process
#   - Logs execution info, timestamps, and results to a timestamped logfile
#   - Sends Telegram notification on completion/failure
#   - Exits with proper status codes (0 for success, 1 for running, >1 for errors)

# ========================
# 🔧 Configuration
# ========================
LOG_DIR="./log/snapraid"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_FILE="$LOG_DIR/snapraid-scrub-${TIMESTAMP}.log"
PID_FILE="./snapraid-scrub.pid"

# Telegram configuration (should be set as environment vars)
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
echo "🕒 Started SnapRAID Scrub: $START_TIME"
echo "📦 Host: $HOSTNAME"
echo "👤 User: $(whoami)"
echo "🔧 Working Directory: $(pwd)"
echo "📄 Log File: $LOG_FILE"
echo "-------------------------------------------"

# ========================
# 🚦 Prevent duplicate run
# ========================
if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null 2>&1; then
    echo "⚠️  SnapRAID scrub already running (PID $(cat "$PID_FILE"))"
    echo "🕒 Checked at: $(date '+%Y-%m-%d %H:%M:%S')"
    exit 1
fi

# ========================
# ▶️ Run SnapRAID Scrub
# ========================
echo "🚀 Starting SnapRAID scrub (50%)..."
nohup snapraid scrub -p 50 -o 10 >> "$LOG_FILE" 2>&1 &
PID=$!
echo "$PID" > "$PID_FILE"

wait $PID
SCRUB_EXIT_CODE=$?
END_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Remove PID file
if [ -f "$PID_FILE" ]; then
    rm -f "$PID_FILE"
    echo "🗑️  Removed PID file: $PID_FILE"
fi

# ========================
# ❌ Handle Failure
# ========================
if [ $SCRUB_EXIT_CODE -ne 0 ]; then
    echo "❌ SnapRAID scrub failed with exit code $SCRUB_EXIT_CODE"
    echo "🕒 Time: $END_TIME"
    echo "=================================================="

    if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
        curl -s -X POST "$TELEGRAM_API_URL" \
            -H "Content-Type: application/json" \
            -d "{
                \"chat_id\": \"$TELEGRAM_CHAT_ID\",
                \"text\": \"❌ *SnapRAID scrub FAILED* on _${HOSTNAME}_\\n🕒 Start: ${START_TIME}\\n🕓 End: ${END_TIME}\\n📄 Log: ${LOG_FILE}\\nExit code: ${SCRUB_EXIT_CODE}\",
                \"parse_mode\": \"Markdown\"
            }" >/dev/null 2>&1
    fi

    exit 2
fi

# ========================
# ✅ Success
# ========================
echo "✅ SnapRAID scrub completed successfully!"
echo "🕒 Finished at: $END_TIME"
echo "=================================================="

# Send Telegram success notification
if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
    curl -s -X POST "$TELEGRAM_API_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"chat_id\": \"$TELEGRAM_CHAT_ID\",
            \"text\": \"✅ *SnapRAID scrub completed successfully* on _${HOSTNAME}_\\n🕒 Start: ${START_TIME}\\n🕓 End: ${END_TIME}\\n📄 Log: ${LOG_FILE}\",
            \"parse_mode\": \"Markdown\"
        }" >/dev/null 2>&1
fi

exit 0
