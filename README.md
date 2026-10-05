# 📱➜🖥️ Pocket VPS

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

> 🆕 **Never used a terminal before?** No problem — every command below can be copy-pasted. Nothing here needs root, and nothing can break your device.

---

## ⚡ Quick Install (3 steps)

### Step 1 — Install Termux on the Android device

1. On the Android device, open the browser and go to **[F-Droid Termux page](https://f-droid.org/packages/com.termux/)** (or [GitHub Releases](https://github.com/termux/termux-app/releases))
2. Download and install the APK (allow "install from unknown sources" if asked)

> ⚠️ **Never** use the Play Store version — it's outdated and broken. This is the #1 mistake beginners make.

### Step 2 — Open Termux and paste this ONE line

Open the Termux app, then **long-press anywhere on the black screen → Paste**, and press Enter:

```bash
pkg install -y curl && curl -fsSL https://raw.githubusercontent.com/technology1520-afk/pocket-vps/main/install.sh | bash
```

☕ Grab a coffee — it downloads Debian, Node.js 22, PM2 and sets everything up (~5-10 min depending on internet). You'll see progress text scroll by; that's normal.

> 💡 **How to paste in Termux:** long-press on the screen → **Paste**. (Ctrl+V doesn't work — Termux has its own menu.)

### Step 3 — Set a password & connect from your PC

**3a. On the tablet (in Termux), set a password:**

```bash
passwd
```
You'll be asked to type a password twice (the screen shows nothing while typing — that's normal, just type it).

**3b. Find your tablet's IP address** — the installer prints it at the end. Missed it? Type this in Termux:

```bash
ifconfig wlan0 | grep 'inet '
```
Look for something like `inet 192.168.1.42` — that number is your tablet's IP.

**3c. From your PC, connect:**

```powershell
# Windows PowerShell / macOS / Linux:
ssh -p 8022 u0_aXXX@192.168.1.42
#  ↑ replace u0_aXXX with the username the installer printed
#  ↑ replace 192.168.1.42 with YOUR tablet's IP from step 3b
# password = the one you set in 3a
```

**3d. Enter the Debian server:**

```bash
proot-distro login debian    # you are now ROOT in a full Debian 13 system
pm2 ls                       # PM2 process manager is ready
```

🎉 **Done — your tablet is now a Linux server.** Keep reading to add agents, or jump to [Troubleshooting](#%EF%B8%8F-troubleshooting) if something didn't work.

---

## 🔐 SSH Access — sshd & passwords explained

The installer starts **sshd** (the SSH server) on the tablet automatically, on **port 8022**. 

> ❓ **Why port 8022 and not 22?** Android doesn't allow normal apps to use port 22. This is normal, not an error — just remember to always add `-p 8022` when connecting.

### 1. Set your SSH password (on the tablet, in Termux)

```bash
passwd
# New password: <type a password>
# Retype new password: <same password>
# New password was successfully set.
```

You'll use this password when connecting from your PC — **or** skip passwords entirely by adding your PC's SSH key (next section).

### 2. Two ways to log in from your PC

**Option A — Password (easiest):**
```powershell
ssh -p 8022 u0_aXXX@<tablet-ip>
# prompts for the password you set with `passwd`
```

**Option B — SSH key (more secure, no password to type):**

From your PC, push your public key to the tablet:
```powershell
# Windows PowerShell:
type "$HOME\.ssh\id_ed25519.pub" | ssh -p 8022 u0_aXXX@<tablet-ip> "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# macOS / Linux:
cat ~/.ssh/id_ed25519.pub | ssh -p 8022 u0_aXXX@<tablet-ip> "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```
> Don't have a key on your PC yet? Generate one first: `ssh-keygen -t ed25519` (press Enter through all the questions).

After this, `ssh -p 8022 u0_aXXX@<tablet-ip>` logs straight in — no password.

### 3. If SSH stops responding ("Connection refused")

Android sometimes kills sshd in the background. Fix in 5 seconds — open **Termux on the tablet** and type:

```bash
sshd
```

That's it — the keeper scripts will also auto-restart sshd within 30s, but typing `sshd` works instantly. (If you just restarted the tablet, open Termux once — the boot script auto-starts everything.)

### 4. Changing / resetting the password later

```bash
passwd              # on the tablet in Termux — set a new one
```

> ⚠️ **After changing SSH config** (not the password), restart sshd **from the tablet screen**, not over SSH: `pkill sshd; sshd` — restarting over SSH kills your own connection. Password changes don't need a restart.

### 5. Inside Debian (the second layer)

The Debian container also runs its own sshd (port 8023, managed by the `debian-sshd` keeper). You normally don't need it — just hop in from Termux:

```bash
proot-distro login debian
```

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
| Typing feels weird / no paste option | Long-press the screen → Paste; also try the extra-key row (CTRL, etc.) |

**Golden rule:** the tablet must stay awake (screen can be off, but Termux alive) and plugged in for 24/7 use. If everything ever seems dead — open Termux once, everything comes back.

---

## 🗑️ Uninstall

```bash
# in Termux:
bash <(curl -fsSL https://raw.githubusercontent.com/technology1520-afk/pocket-vps/main/uninstall.sh)
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
