# 📱➜🖥️ Tablet VPS — Turn Any Android Phone/Tablet Into a Debian Server

One command turns a fresh **Termux** install into a 24/7 headless **Debian VPS** with PM2, SSH access, keepers, and log rotation — the exact setup proven on a Samsung Galaxy Tab A11 running weeks of uptime.

```bash
curl -fsSL https://raw.githubusercontent.com/technology1520-afk/tablet-vps/main/install.sh | bash
```

---

## What you get

| Layer | What | Why |
|---|---|---|
| **Termux** (host) | sshd on port 8022, wake-lock, PM2 + keeper, boot auto-start | Android kills background apps — the keepers + wake-lock + boot script survive it |
| **Debian 13** (proot) | Full apt ecosystem, Node.js 22, PM2, sshd | Real Linux userland with cloud-VPS package parity, zero root needed |
| **PM2** (both layers) | Process manager + logrotate (10MB × 4) | Crashed agents auto-restart; logs never fill your disk |
| **Keepers** | `debian-sshd` + `vps-keeper` watchdogs | Self-healing: sshd dies → restarted in ≤30s |

## Requirements

- Android 7+ phone or tablet ([Termux from F-Droid](https://f-droid.org/packages/com.termux/) — **never** the Play Store build)
- ~2 GB free storage
- Same Wi-Fi as your PC (or USB + `adb forward tcp:8022 tcp:8022`)

## Install

1. Install **Termux** from F-Droid
2. Paste this into Termux:

```bash
pkg install -y curl && curl -fsSL https://raw.githubusercontent.com/technology1520-afk/tablet-vps/main/install.sh | bash
```

3. Add your PC's SSH key (from your PC):

```bash
type "$HOME\.ssh\id_ed25519.pub" | ssh -p 8022 u0_a<uid>@<tablet-ip> "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

> Don't know your tablet's UID or IP? The installer prints both at the end.

4. Connect and enter the Debian VPS:

```powershell
ssh -p 8022 u0_a<uid>@<tablet-ip>     # → Termux layer
proot-distro login debian             # → Debian VPS (root)
pm2 ls                                # your process manager
```

## Adding AI agents (Hermes, Codex, whatever)

Drop the agent into `~/vps/agents/<name>/` **inside Debian**, then:

```bash
pm2 start ~/vps/agents/<name>/agent.js --name my-agent
pm2 save
```

Crashed? PM2 restarts it. Tablet rebooted? `pm2 resurrect` (boot script does this automatically).

## Architecture

```
Android (kernel: power/thermal/Wi-Fi management)
 └── Termux (sshd :8022, wake-lock, PM2 layer-1, boot script)
      └── proot Debian 13 (sshd, Node 22, PM2 layer-2, /root/vps)
           └── your AI agents (pm2-managed, auto-restart)
```

**Why not bare-metal Linux?** Samsung tablets lose charging, Wi-Fi, and thermal control under pure Linux kernels. Android as the "hypervisor" keeps the hardware actually working — read [the full rationale](RATIONALE.md).

## Files

| File | Purpose |
|---|---|
| `install.sh` | The one-line installer (idempotent — safe to re-run) |
| `RATIONALE.md` | Why Termux+proot beats bare-metal on Samsung hardware |
| `agents/example-agent/` | Minimal example agent you can copy |
| `uninstall.sh` | Full removal |

## Updating

```bash
# inside Termux:
pm2 update
# inside Debian:
apt update && apt upgrade -y && npm update -g pm2
```

## Troubleshooting

- **"Connection refused" on port 8022** → open Termux on the tablet, type `sshd`, retry
- **"Permission denied (publickey)"** → your key isn't in `~/.ssh/authorized_keys` on the tablet; re-add it
- **VPS feels slow** → check `pm2 monit`; Android may have killed PM2 — reopen Termux, `pm2 resurrect`
- **Wi-Fi IP changed** → set a DHCP reservation on your router for the tablet's MAC

## License

MIT — fork it, brand it, ship it.
