#!/data/data/com.termux/files/usr/bin/bash
# uninstall.sh — removes the tablet VPS stack
echo "Stopping PM2 processes (Termux layer)..."
pm2 delete all >/dev/null 2>&1
pm2 kill >/dev/null 2>&1

echo "Removing boot script + keepers..."
rm -f ~/.termux/boot/00-vps-start ~/debian-sshd-keeper.sh

echo "Removing Debian container (this deletes /root/vps inside it too)..."
read -p "Type YES to delete Debian + all agents: " A
[ "$A" = "YES" ] || { echo "Aborted."; exit 1; }
proot-distro remove debian

echo "Done. Termux is clean (openssh/nodejs/pm2 packages remain, remove with 'pkg uninstall' if wanted)."
termux-wake-unlock 2>/dev/null
