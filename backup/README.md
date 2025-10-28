# 📦 rsync-wrapper – A One-liner Backup Tool

[![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Sync Engine](https://img.shields.io/badge/Tool-rsync-0468A0?logo=rsync&logoColor=white)](https://rsync.samba.org/)
[![Notifications](https://img.shields.io/badge/Alerts-Telegram-2CA5E0?logo=telegram&logoColor=white)](https://core.telegram.org/bots)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **Copy files in the background, log everything, track the PID, and get Telegram alerts when it’s done.**

---

## 1️⃣ Overview

`rsync-wrapper.sh` is a small, self-contained Bash wrapper around **`rsync`** that gives you a safer, smarter way to run background copies.

| Feature | Description |
|----------|-------------|
| **Background copy** | Runs `rsync` via `nohup` in the background, so it keeps running after you log out. |
| **Logging** | Every line of output (stdout + stderr) goes to `./logs/rsync/rsync_YYYY-MM-DD--HH-MM-SS.log`. |
| **PID tracking** | The PID of the running process is stored in `./rsync_YYYY-MM-DD--HH-MM-SS.pid`. |
| **Telegram notifications** | Sends success/failure alerts through your Telegram bot when the copy completes. |
| **Safe paths** | Automatically appends a trailing slash (`/`) so you copy the *contents* of a directory, not the directory itself. |
| **Minimal dependencies** | Only Bash, `rsync`, `nohup`, and `curl` (for Telegram) are required. |

> 💡 *Why use this instead of plain `rsync`?*  
> It gives you persistent logs, background execution, PID tracking, and instant Telegram updates.

---

## 2️⃣ Prerequisites

| Requirement | Version |
|-------------|----------|
| **Linux / macOS** (Bash shell) | ≥ 3.2 |
| **rsync** | ≥ 3.0 |
| **nohup** | Standard Unix utility |
| **curl** | Required for Telegram notifications |

### 📦 Install on Linux

```bash
sudo apt install rsync curl    # Debian/Ubuntu
# or
sudo dnf install rsync curl    # Fedora/CentOS
````

---

## 3️⃣ Configuration

```bash
# 1️⃣ Make the script executable
chmod +x rsync-wrapper.sh

# 2️⃣ (Optional) Move it somewhere in your PATH
sudo mv rsync-wrapper.sh /usr/local/bin/rsync-wrapper
```


> ✅ You can also keep it in your home directory — just run `./rsync-wrapper.sh`.

---

## 4️⃣ Usage

```bash
# Basic syntax
rsync-wrapper /path/to/source/ /path/to/destination/

# Example with spaces
rsync-wrapper "/var/www/html" "/mnt/backup/html"
```

> ⚠️ Always quote any path containing spaces or special characters.

### Default rsync options

The script runs:

```bash
rsync -avh --progress "$SRC" "$DST"
```

If you want to exclude patterns, enable deletion, or fine-tune behavior, edit the `RSYNC_CMD` line in the script.

---

## 5️⃣ Logging & PID Tracking

| File    | Purpose                             | Location                                      |
| ------- | ----------------------------------- |-----------------------------------------------|
| **Log** | Full rsync output (stdout + stderr) | `./logs/rsync/rsync_YYYY-MM-DD--HH-MM-SS.log` |
| **PID** | PID of the running rsync process    | `./rsync_YYYY-MM-DD--HH-MM-SS.pid`            |

### 🔍 Inspect a running job

```bash
tail -f ./logs/rsync/rsync_2025-10-28--14-20-00.log
```

### 🛑 Stop a running job

```bash
kill "$(cat ./rsync_2025-10-28--14-20-00.pid)"
```

---

## 6️⃣ Telegram Notifications (Optional)

To receive Telegram alerts, export your bot token and chat ID before running the script:

```bash
export TELEGRAM_BOT_TOKEN="123456789:ABCDEF-your-bot-token"
export TELEGRAM_CHAT_ID="987654321"
```

You’ll then receive messages like:

* ✅ **Success:**
  “Rsync completed successfully on *server01*
  🕒 Start: 2025-10-28 14:20:00
  🕓 End: 2025-10-28 14:52:33
  📄 Log: ./logs/rsync/rsync_2025-10-28--14-20-00.log”

* ❌ **Failure:**
  “Rsync FAILED on *server01* (exit code 23).”

If Telegram variables aren’t set, notifications are skipped silently.

---

## 7️⃣ Exit Codes

| Code | Meaning                        |
| ---- | ------------------------------ |
| `0`  | Success                        |
| `1`  | Invalid arguments              |
| `2`  | rsync failure or process error |

---

## 8️⃣ Troubleshooting

| Symptom                    | Likely Cause                         | Fix                                            |
| -------------------------- | ------------------------------------ |------------------------------------------------|
| “Usage: …” printed         | Missing or extra arguments           | Provide **exactly two** paths.                 |
| Log file missing           | Permission or directory issue        | Ensure `./logs/rsync/` exists and is writable. |
| “Permission denied” errors | User lacks write access              | Run as a user with the proper permissions.     |
| No Telegram message        | Missing or invalid bot token/chat ID | Verify both environment variables.             |

---

## 9️⃣ Customization

You can easily tailor the wrapper:

* 🗂️ **Change log directory** – edit `LOG_DIR` in the script.
* ⚙️ **Add more rsync flags** – extend `RSYNC_CMD`.
* 🔔 **Change notification method** – replace the Telegram block with Slack, email, or another API.
* 🕑 **Automate backups** – schedule runs via cron or systemd timers.
