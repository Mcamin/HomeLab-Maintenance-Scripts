### 📘 README — Disable Proxmox Subscription Popup

#### 🧩 Description

This script disables the **“No valid subscription”** popup in the **Proxmox VE** web interface.
It works by patching the JavaScript file that controls the popup (`proxmoxlib.js`) and restarting the web service.

The script is **safe**, **non-destructive**, and **automatically creates a backup** of the original file before applying any changes.

---

#### ⚙️ Installation

1. Create the script:

   ```bash
   nano /usr/local/bin/disable-proxmox-popup.sh
   ```

   Paste the contents of the script, then save and exit.

2. Make it executable:

   ```bash
   chmod +x /usr/local/bin/disable-proxmox-popup.sh
   ```

---

#### 🚀 Usage

Run this command anytime after updating Proxmox:

```bash
/usr/local/bin/disable-proxmox-popup.sh
```

* A backup of the original file will be created automatically.
* The Proxmox web service (`pveproxy`) will restart.
* Refresh your browser with **Ctrl + Shift + R** to clear cached JavaScript.

---

#### 🔁 Optional: Auto-run after system updates

To automatically reapply the patch after Proxmox package updates, create a dpkg hook:

```bash
echo '/usr/local/bin/disable-proxmox-popup.sh || true' > /etc/apt/apt.conf.d/99-disable-proxmox-popup
```

or add this line to root’s crontab:

```
@reboot /usr/local/bin/disable-proxmox-popup.sh >/var/log/disable-proxmox-popup.log 2>&1
```

---

#### 🧾 Notes

* Works on **Proxmox VE 7.x, 8.x, and 9.x**
* Must be run as `root` (default on Proxmox shell)
* Backups are stored as
  `/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.bak.YYYY-MM-DD_HH-MM-SS`
* To undo: restore the backup and restart `pveproxy`.

