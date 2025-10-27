## 🧩 README — SnapRAID Maintenance Automation Suite

### 📘 Overview

This set of scripts automates your **SnapRAID maintenance cycle** with full logging, concurrency protection, and **Telegram notifications**.

It consists of:

| Script              | Purpose                                                                                                                                            |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `snapraid-job.sh`   | Entry point — triggers a SnapRAID sync job in the background and logs the run.                                                                     |
| `snapraid-sync.sh`  | Handles the main SnapRAID `sync` operation, prevents duplicate runs, manages logs, and starts the scrub job automatically after a successful sync. |
| `snapraid-scrub.sh` | Runs the SnapRAID `scrub` process (default: 50%), with duplicate-run protection, logging, and Telegram status messages.                            |

Each script creates timestamped logs under `./log/snapraid/`.

---

## ⚙️ Requirements

### 🧱 System

* Linux server running **SnapRAID**
* Bash shell (`/bin/bash`)
* `curl` (for Telegram API)
* `tee`, `nohup`, `ps`, and `hostname` (default utilities)

### 📦 SnapRAID

Ensure SnapRAID is installed and configured properly:

```bash
snapraid --version
snapraid status
```

You should have a valid `snapraid.conf` file in your working directory or `/etc/snapraid.conf`.

---

## 🗂️ File Structure

```
/home/<user>/snapraid/
│
├── snapraid-job.sh          # Orchestrator – starts sync in background
├── snapraid-sync.sh         # Main sync logic + triggers scrub
├── snapraid-scrub.sh        # Performs scrub, handles notifications
├── snapraid-sync.pid        # PID file (created automatically)
├── log/
│   └── snapraid/            # All timestamped log files stored here
└── snapraid.content         # SnapRAID content file (managed by SnapRAID)
```

---

## 🔧 Configuration

### 1️⃣ Make scripts executable

```bash
chmod +x snapraid-job.sh snapraid-sync.sh snapraid-scrub.sh
```

### 2️⃣ Configure environment variables (Telegram)

The scripts use Telegram Bot API variables to send notifications.
You can set them **system-wide** or **per session**.

#### 🧩 Option A — Temporary (for current shell only)

```bash
export TELEGRAM_BOT_TOKEN="123456789:ABCDEFGyourbottoken"
export TELEGRAM_CHAT_ID="123456789"
```

#### 🧩 Option B — Permanent (for all sessions)

Add them to your shell environment:

```bash
sudo nano /etc/environment
```

Add lines:

```
TELEGRAM_BOT_TOKEN="123456789:ABCDEFGyourbottoken"
TELEGRAM_CHAT_ID="123456789"
```

Then reload:

```bash
sudo source /etc/environment
```

> 🧠 Tip: You can test the Telegram configuration with
>
> ```bash
> curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
> -d chat_id="${TELEGRAM_CHAT_ID}" -d text="🔔 Telegram test from SnapRAID"
> ```

---

## ▶️ Usage Guide

### 1️⃣ Start the full job (recommended)

Run the orchestrator — it triggers the full sync cycle asynchronously:

```bash
./snapraid-job.sh
```

* It logs the process to a timestamped file (e.g., `log/snapraid/snapraid-job-2025-10-26_14-30-00.log`).
* The sync runs in the background.
* When sync finishes, `snapraid-sync.sh` automatically triggers the scrub job.

---

### 2️⃣ Run sync manually (foreground)

If you want to execute the sync script directly and wait for completion:

```bash
./snapraid-sync.sh
```

This will:

* Prevent duplicate runs (via PID lock)
* Log everything to `log/snapraid/snapraid-sync-<timestamp>.log`
* Send Telegram notification on success or failure
* Launch `snapraid-scrub.sh` automatically if sync succeeds

---

### 3️⃣ Run scrub manually (standalone)

To run just the scrub (e.g., for maintenance testing):

```bash
./snapraid-scrub.sh
```

* Runs `snapraid scrub -p 50 -o 10`
  (`-p 50` = scrub 50% of blocks, `-o 10` = scrub oldest 10% first)
* Creates timestamped log file
* Sends Telegram message on success/failure

---

## 🧱 Concurrency Protection

Each script uses a `.pid` file to prevent duplicate runs:

| Script              | PID File             |
| ------------------- | -------------------- |
| `snapraid-sync.sh`  | `snapraid-sync.pid`  |
| `snapraid-scrub.sh` | `snapraid-scrub.pid` |

If the PID in the file corresponds to a running process, the script exits with a message like:

```
⚠️  SnapRAID sync already running (PID 1234)
```

---

## 🧾 Exit Codes

| Code | Meaning                                |
| ---- | -------------------------------------- |
| `0`  | Completed successfully                 |
| `1`  | Already running                        |
| `2`  | Sync or scrub failed                   |
| `3`  | Scrub script missing or not executable |

---

## 🕒 Automation via Cron

To automate periodic sync + scrub, add a cron job:

```bash
crontab -e
```

Example: Run every day at 3 AM

```
0 3 * * * cd /home/<user>/snapraid && ./snapraid-job.sh >/dev/null 2>&1
```

---

## 🧩 Example Log Output

```
==================================================
🕒 Started SnapRAID Sync: 2025-10-26 03:00:00
📦 Host: NAS01
👤 User: root
📄 Log File: ./log/snapraid/snapraid-sync-2025-10-26_03-00-00.log
-------------------------------------------
🚀 Starting SnapRAID sync...
✅ SnapRAID sync completed successfully!
🚀 Running scrub script: ./snapraid-scrub.sh
✅ Scrub script executed successfully!
==================================================
```

---

## 🧠 Tips

* Ensure all SnapRAID drives are mounted before running sync/scrub.
* Telegram messages use Markdown — avoid special characters in hostnames if possible.
* You can adjust the scrub parameters (`-p`, `-o`) inside `snapraid-scrub.sh`.

---

## 📦 Summary

| Script                | Role         | Trigger              | Result                     |
| --------------------- | ------------ | -------------------- | -------------------------- |
| **snapraid-job.sh**   | Orchestrator | Manual or cron       | Starts background sync     |
| **snapraid-sync.sh**  | Sync runner  | By job.sh or direct  | Syncs data, triggers scrub |
| **snapraid-scrub.sh** | Scrub runner | By sync.sh or direct | Verifies data blocks       |

