#!/data/data/com.termux/files/usr/bin/bash
###############################################
#  TABLET VPS ONE-LINE INSTALLER
#  Turns a fresh Termux (Android) into a 24/7
#  headless VPS: Debian proot + Node.js + PM2
#  + SSH + keepers + log rotation.
#
#  Install from anywhere:
#    curl -fsSL https://raw.githubusercontent.com/technology1520-afk/tablet-vps/main/install.sh | bash
###############################################
set -e

echo ""
echo "=============================================="
echo "   TABLET VPS INSTALLER v1.0"
echo "   Termux -> Debian proot VPS + PM2"
echo "=============================================="

echo "[1/8] Updating packages & installing core tools..."
pkg update -y >/dev/null 2>&1 || true
pkg install -y openssh proot-distro nodejs-lts git tmux ncurses-utils >/dev/null 2>&1
echo "      done."

echo "[2/8] Holding wake-lock so Android won't kill the VPS..."
termux-wake-lock 2>/dev/null || true

echo "[3/8] Installing Debian (proot-distro)..."
if ! proot-distro list 2>/dev/null | grep -q "debian.*installed"; then
  proot-distro install debian >/dev/null 2>&1
fi
echo "      done."

echo "[4/8] Preparing SSH authorized_keys..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh
[ -f ~/.ssh/authorized_keys ] || touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
echo "      (add your PC's ~/.ssh/id_*.pub line to ~/.ssh/authorized_keys, or use password auth)"

echo "[5/8] Configuring Debian: keys + Node.js 22 + PM2 + sshd..."
proot-distro login debian -- bash -c '
set -e
mkdir -p /root/.ssh /root/vps/agents /root/vps/logs /root/vps/bin
cp /data/data/com.termux/files/home/.ssh/authorized_keys /root/.ssh/authorized_keys 2>/dev/null || true
chmod 700 /root/.ssh; chmod 600 /root/.ssh/authorized_keys
apt-get update -qq
apt-get install -y -qq openssh-server curl git build-essential iproute2 procps >/dev/null 2>&1
mkdir -p /etc/ssh/sshd_config.d
printf "PermitRootLogin yes\nPubkeyAuthentication yes\nPasswordAuthentication yes\n" > /etc/ssh/sshd_config.d/99-vps.conf
sed -i "s/session    required     pam_loginuid.so/session    optional     pam_loginuid.so/" /etc/pam.d/sshd
curl -fsSL https://deb.nodesource.com/setup_22.x | bash - >/dev/null 2>&1
apt-get install -y -qq nodejs >/dev/null 2>&1
npm install -g pm2 >/dev/null 2>&1
echo "      deb-root ready"
'

echo "[6/8] Installing keepers (watchdogs)..."
cat > ~/debian-sshd-keeper.sh << '"'"'KEEPER'"'"'
#!/data/data/com.termux/files/usr/bin/bash
while true; do
  proot-distro login debian -- bash -c '"'"'pgrep -f "sshd -p 8023" >/dev/null || (setsid /usr/sbin/sshd -p 8023 >/dev/null 2>&1 &)'"'"' 2>/dev/null
  sleep 30
done
KEEPER
chmod +x ~/debian-sshd-keeper.sh
pm2 start ~/debian-sshd-keeper.sh --name debian-sshd >/dev/null 2>&1
pm2 save --force >/dev/null 2>&1
proot-distro login debian -- bash -c '
cat > /root/vps/bin/vps-keeper.sh << "VK"
#!/bin/bash
while true; do
  pgrep -x sshd >/dev/null || /usr/sbin/sshd 2>/dev/null
  sleep 60
done
VK
chmod +x /root/vps/bin/vps-keeper.sh
pm2 start /root/vps/bin/vps-keeper.sh --name vps-keeper >/dev/null 2>&1
pm2 save --force >/dev/null 2>&1
' 2>/dev/null
echo "      done."

echo "[7/8] Installing log rotation + boot auto-start..."
npm install -g pm2-logrotate >/dev/null 2>&1 || true
pm2 set pm2-logrotate:max_size 10M >/dev/null 2>&1
pm2 set pm2-logrotate:retain 4 >/dev/null 2>&1
pm2 set pm2-logrotate:compress true >/dev/null 2>&1
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/00-vps-start << '"'"'BOOT'"'"'
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
sshd 2>/dev/null
sleep 2
pm2 resurrect >/dev/null 2>&1
pm2 save --force >/dev/null 2>&1
BOOT
chmod +x ~/.termux/boot/00-vps-start
sshd 2>/dev/null || true
echo "      done."

echo "[8/8] Saving PM2 process list..."
pm2 save --force >/dev/null 2>&1

IP=$(ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | awk "{print \$2}" | head -1)
echo ""
echo "=============================================="
echo "   INSTALL COMPLETE"
echo "=============================================="
echo "Connect from your PC (same Wi-Fi):"
echo "   ssh -p 8022 $USER@$IP"
echo ""
echo "Enter the Debian VPS:"
echo "   proot-distro login debian"
echo ""
echo "Manage agents:"
echo "   pm2 ls | pm2 monit | pm2 logs"
echo "   agents live in ~/vps/agents/ (Debian: /root/vps/agents/)"
echo "=============================================="
