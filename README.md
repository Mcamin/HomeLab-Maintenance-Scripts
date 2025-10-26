# 🧩 HomeLab Maintenance Scripts

## 📘 Overview

This repository is a collection of **shell scripts** designed to automate and simplify system maintenance tasks for a home lab or self-hosted environment.

The scripts are organized by function — e.g., data integrity (SnapRAID), backups (rsync), and infrastructure tuning (Proxmox tweaks).

Most scripts are **bash-based**, lightweight, and written for **non root execution** (no `sudo` required).

---

## 🗂️ Repository Structure

```
homelab-scripts/
│
├── snapraid/                      # Automated SnapRAID sync/scrub cycle
│   ├── snapraid-job.sh
│   ├── snapraid-sync.sh
│   ├── snapraid-scrub.sh
│   └── README.md
│
├── proxmox/                       # Quality-of-life tools for Proxmox VE
│   ├── disable-proxmox-popup.sh
│   └── README.md
│
├── backup/                        # Simple rsync-based copy/backup jobs
│   ├── copy.sh
│   └── README.md
│
└── README.md                      # (this file)
```

---

## ⚙️ Requirements

### Common

* Linux environment (tested on Debian/Ubuntu-based systems)
* `/bin/bash`
* Core utilities:  `nohup`, `curl`, `rsync`
* Root access (some scripts assume root privileges)
* Optional: Internet access for Telegram notifications

---

## 🧩 Script Groups

### 📦 1. SnapRAID Automation (`snapraid/`)

Automates SnapRAID integrity maintenance with structured logs and Telegram reporting.

| Script              | Function                                                 |
| ------------------- | -------------------------------------------------------- |
| `snapraid-job.sh`   | Orchestrates the cycle, runs sync in background          |
| `snapraid-sync.sh`  | Handles safe sync with PID lock, triggers scrub          |
| `snapraid-scrub.sh` | Runs partial scrub (default 50%), sends Telegram updates |

Each run produces detailed, timestamped logs in `./log/snapraid/`.

See the dedicated [snapraid/README.md](snapraid/README.md) for:

* Setup instructions
* Cron/systemd automation
* Environment variable configuration for Telegram

---

### 🖥️ 2. Proxmox Utilities (`proxmox/`)

Small tools for improving Proxmox VE usability and maintenance.

| Script                     | Purpose                                                                |
| -------------------------- | ---------------------------------------------------------------------- |
| `disable-proxmox-popup.sh` | Permanently disables the *“No valid subscription”* popup after updates |

See [proxmox/README.md](proxmox/README.md) for setup details and auto-patch options.

---

### 💾 3. Backup & Copy (`backup/`)

A portable rsync wrapper for quick one-line copies or backups.

| Script    | Purpose                                                      |
| --------- | ------------------------------------------------------------ |
| `copy.sh` | Runs `rsync` in the background with logging and PID tracking |

**Features:**

* Creates `rsync_<timestamp>.log` and `.pid`
* Preserves attributes with `-avh`
* Runs detached via `nohup`
* Useful for quick ad-hoc or automated backups

Usage:

```bash
./copy.sh /var/www/html /mnt/backup/html
```

See [backup/README.md](backup/README.md) for more examples.

---

## 📩 Telegram Integration

The SnapRAID scripts use Telegram Bot API notifications.

To enable them system-wide, add your credentials to `/etc/environment`:

```
TELEGRAM_BOT_TOKEN="123456789:ABCD_EFGHIJKL"
TELEGRAM_CHAT_ID="987654321"
```

Reload environment variables:

```bash
source /etc/environment
```

Test it:

```bash
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
-d chat_id="${TELEGRAM_CHAT_ID}" \
-d text="✅ Telegram integration working!"
```

---

## 🕒 Automation Examples

### 🧭 Cron Jobs

Example daily automation:

```bash
0 3 * * * cd /home/<your-user>/snapraid && ./snapraid-job.sh >/dev/null 2>&1
```

### ⚙️ Systemd Timer (optional)

Some scripts can be wrapped into a `systemd` service and timer for more reliable scheduling.
See the individual README files for ready-made unit examples.

---

## 🧱 Development Notes

* Scripts are modular and self-contained.
* Logs are timestamped for easy troubleshooting.
* All code is POSIX-compliant with Bash-specific enhancements.
* `set -euo pipefail` ensures safe execution (abort on error/undefined var).

---

## 🧩 Roadmap / To-Do

---

## 🪪 License

All scripts are released under the **MIT License** — feel free to modify and reuse them in your own home-lab or production environments.

---

## 🧠 Credits

Created and maintained by **info@madev.de**
Community feedback, testing, and contributions are welcome.

