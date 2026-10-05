# 📱➜🖥️ Tablet VPS

**Turn any Android phone or tablet into a real 24/7 Debian Linux server — in about 10 minutes, with one command. No root. No custom ROM. No risk of bricking.**

[![Install](https://img.shields.io/badge/install-one%20line-blue)](#-quick-install-3-steps) [![Platform](https://img.shields.io/badge/platform-Android%207%2B-green)](#-requirements) [![License](https://img.shields.io/badge/license-MIT-yellow)](LICENSE)

---

## 👋 What is this?

This repo contains everything needed to convert a spare Android device into a **headless Debian Linux server** that:

- ✅ runs 24/7 plugged into the wall (Android manages charging & heat safely)
- ✅ is reachable over SSH from your PC (Wi-Fi or USB)
- ✅ hosts **any AI agent** (Hermes, OpenClaw, your own bots...) via **PM2**
- ✅ **self-heals**: if sshd or a service dies, a watchdog restarts it in ≤60s
- ✅ survives reboots: reopen Termux once and the whole stack comes back

The exact setup is running 24/7 on a Samsung Galaxy Tab A11.

---

## ⚡ Quick Install (3 steps)

### Step 1 — Install Termux on the Android device

Get it from **[F-Droid](https://f-droid.org/packages/com.termux/)** or [GitHub Releases](https://github.com/termux/termux-app/releases).

> ⚠️ **Never** use the Play Store version — it's outdated and broken.

### Step 2 — Open Termux and paste this ONE line:

```bash
pkg install -y curl && curl -fsSL https://raw.githubusercontent.com/technology1520-afk/tablet-vps/main/install.sh | bash
```

 ☕ Grab a coffee — it downloads Debian, Node.js 22, PM2 and sets everything up (~5-10 min depending on internet).

### Step 3 — Connect from your PC

When the installer finishes it prints your tablet's **IP** and **username**. From your PC:

```powershell
# Windows PowerShell / macOS / Linux:
ssh -p 8022 u0_aXXX@192.168.1.XX     # ← use the IP/username the installer printed
# password = the Termux password you set (run `passwd` in Termux to set one)
```

Then hop into the Debian server:

```bash
proot-distro login debian    # you are now ROOT in a full Debian 13 system
pm2 ls                       # PM2 process manager is ready
```

> 💡 **Set a password first** (in Termux): run `passwd` so SSH login works.

---

## 🤖 Adding AI Agents

Your agents live in `/root/vps/agents/` inside Debian. Example — run a Node.js bot:

```bash
proot-distro login debian
cd /root/vps/agents
cp -r example-agent my-agent                     # copy the included template
pm2 start ~/vps/agents/my-agent/agent.js --name my-agent
pm2 save                                         # survives reboots
```

That's it. PM2 will:
- ✅ restart it if it crashes
- ✅ restart it if the tablet reboots (boot script does this automatically)
- ✅ keep logs rotated at 10MB (never fills your disk)

**Works with:** Hermes Agent, OpenClaw bots, Discord/Telegram bots, web servers, cron jobs — anything that runs on Linux.

---

## 🧱 How it works (the architecture)

```
Android (kernel — handles charging, heat, Wi-Fi safely)
   └── Termux (sshd :8022, wake-lock, PM2 #1, boot script)
        └── Debian 13 in proot (Node 22, PM2 #2, sshd, /root/vps)
             └── YOUR AGENTS (pm2-managed, auto-restart)
```

| Layer | Components | Purpose |
|---|---|---|
| Android | stock kernel | charging + thermal + Wi-Fi (never breaks) |
| Termux | sshd, wake-lock, PM2, boot script | entry point + survives Android killing background apps |
| Debian (proot) | Node.js 22, PM2, openssh-server, apt | a real Linux server, cloud-VPS package parity |
| Keepers | `debian-sshd`, `vps-keeper` | watchdogs: anything dies → restarted in ≤60s |

**Why not install Linux directly (no Android)?** Samsung tablets lose charging, Wi-Fi, and thermal control under pure Linux. Android as the base is what makes 24/7 operation actually possible → full explanation in [RATIONALE.md](RATIONALE.md).

---

## 📋 Requirements

| Requirement | Detail |
|---|---|
| Device | Any Android 7+ phone or tablet |
| Termux | From [F-Droid](https://f-droid.org/packages/com.termux/) only |
| Storage | ~2 GB free |
| Network | Same Wi-Fi as your PC (or USB with adb) |

---

## 🔧 Everyday commands

```bash
# On the tablet (Termux):
pm2 ls                      # see all processes
pm2 monit                   # live CPU/RAM dashboard
proot-distro login debian   # enter the Debian VPS

# Inside Debian (as root):
pm2 start ~/vps/agents/<name>/agent.js --name my-agent
pm2 logs my-agent           # tail logs
pm2 save                    # make the process list survive reboots
```

---

## 🛠️ Troubleshooting

| Problem | Fix |
|---|---|
| `Connection refused` on port 8022 | Termux sshd died → open Termux on the tablet, type `sshd`, retry |
| `Permission denied (publickey)` | Your key isn't in the tablet's `~/.ssh/authorized_keys` — re-add it, or use password login (`passwd` in Termux) |
| Tablet IP changed after router reboot | Set a DHCP reservation on your router for the tablet |
| Everything frozen | Open Termux on the tablet once → `pm2 resurrect` → all processes return |
| Agent keeps crashing | `pm2 logs <name>` to see why; check RAM with `pm2 monit` |

---

## 🗑️ Uninstall

```bash
# in Termux:
bash <(curl -fsSL https://raw.githubusercontent.com/technology1520-afk/tablet-vps/main/uninstall.sh)
```

---

## ⭐ Why this setup wins

- **No root** → warranty intact, Knox untouched, zero brick risk
- **Android stays the "hardware layer"** → charging + Wi-Fi + thermals always work
- **Everything auto-heals** → watchdogs restart dead processes before you notice
- **Real Debian** → `apt install` anything a cloud VPS can run
- **PM2 × 2 layers** → process management that survives Android's memory killer

## 📄 License

MIT — fork it, brand it, ship it. See [LICENSE](LICENSE).
