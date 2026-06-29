#!/usr/bin/env bash
# tweaks/tier3b-noatime.sh — Bước 3b (noatime) + 3c (verify fstrim).
# Chạy: sudo bash tweaks/tier3b-noatime.sh   |   Rollback: ... --rollback
set -uo pipefail
if [ "$(id -u)" -ne 0 ]; then echo "❌ Cần sudo: sudo bash $0"; exit 1; fi

if [ "${1:-}" = "--rollback" ]; then
  [ -f /etc/fstab.bak-tier3b ] && cp /etc/fstab.bak-tier3b /etc/fstab && echo "đã khôi phục fstab"
  mount -o remount /; echo "remount: $(mount | grep ' / ' | grep -oE '\(.*\)')"
  exit 0
fi

echo "== mount / TRƯỚC: $(mount | grep ' / ' | grep -oE '\(.*\)') =="

if mount | grep ' / ' | grep -q noatime; then
  echo "  (đã có noatime sẵn)"
else
  cp /etc/fstab /etc/fstab.bak-tier3b && echo "  backup -> /etc/fstab.bak-tier3b"
  sed -i 's#\( / ext4 \)defaults\b#\1defaults,noatime#' /etc/fstab
  echo "  fstab dòng / sau sửa:"; grep ' / ext4 ' /etc/fstab | sed 's/^/    /'
  echo "== Áp ngay bằng remount (không cần reboot) =="
  mount -o remount,noatime /
fi
echo "== mount / SAU: $(mount | grep ' / ' | grep -oE '\(.*\)') =="

echo "== 3c) fstrim verify =="
echo "  fstrim.timer: $(systemctl is-enabled fstrim.timer)/$(systemctl is-active fstrim.timer)"
fstrim -v / 2>&1 | sed 's/^/  /'
echo "✅ Xong 3b + 3c. noatime sẽ dính sau reboot (đã ghi fstab)."
