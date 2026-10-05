# Why Termux + proot beats bare-metal Linux on Samsung tablets

If you've flashed Linux onto x86 laptops, the instinct is "wipe Android, install Debian." On Samsung ARM tablets, that almost always backfires:

## 1. Power Management (PMIC)

Samsung's proprietary charging drivers control the PMIC. Under mainline/postmarketOS kernels, tablets frequently:

- refuse to charge while powered on
- misreport battery voltage (your "80%" is a guess)
- overheat with no thermal throttling profile

A 24/7 server that can't charge while running is not a server.

## 2. Wi-Fi firmware

Samsung ships Broadcom/Qualcomm/MediaTek Wi-Fi with proprietary blobs tied to the Android userspace. Bare-metal kernels drop the radio during deep sleep — your SSH session dies the moment the screen turns off.

## 3. Bootloader & Knox

A-series and S-series bootloaders are locked with Knox e-fuses. Flashing a non-Samsung kernel trips Knox (permanently voids warranty apps), and many devices simply hard-brick.

## 4. The alternative that actually works

Keep Android as the **hypervisor** — it handles charging, thermals, radios, and sleep — and run pure Linux on top:

```
Android (kernel: power/thermal/Wi-Fi)
 └── Termux (userland bootstrap, sshd, wake-lock)
      └── proot Debian 13 (your real server)
           └── PM2 → agents/services
```

- **Idle cost:** ~60–100 MB RAM for the whole stack
- **Charging:** Android's own battery-protect (80–85% limit) keeps a wall-powered tablet safe from swelling
- **Wi-Fi:** Android reconnects automatically; your SSH never notices
- **No root, no Knox, no brick risk**

## The catch (and the fix)

Android's memory manager kills background apps. The setup compensates with three layers:

1. `termux-wake-lock` — stops doze from freezing Termux
2. **Phantom-process tuning** — Android counts and kills Termux child processes; the installer's boot script mitigates this
3. **PM2 keepers** — `debian-sshd` and `vps-keeper` watchdogs restart anything that dies, within 30–60 seconds

Plus a `~/.termux/boot/00-vps-start` script: open Termux once after any reboot and the entire stack comes back automatically.
