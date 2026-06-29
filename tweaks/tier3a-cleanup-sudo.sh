#!/usr/bin/env bash
# tweaks/tier3a-cleanup-sudo.sh — Bước 3a (phần SUDO): journal, apt, snap bản cũ.
# Chạy: sudo bash tweaks/tier3a-cleanup-sudo.sh
set -uo pipefail
if [ "$(id -u)" -ne 0 ]; then echo "❌ Cần sudo: sudo bash $0"; exit 1; fi
echo "== df TRƯỚC =="; df -h / | sed 's/^/  /'

echo "== 1) journal vacuum → 200M =="
journalctl --vacuum-size=200M 2>&1 | tail -2 | sed 's/^/  /'

echo "== 2) apt clean =="
echo "  apt archives trước: $(du -sh /var/cache/apt/archives 2>/dev/null | cut -f1)"
apt-get clean
echo "  ✓ đã clean"

echo "== 3) snap: retain=2 + gỡ revision cũ (disabled) =="
snap set system refresh.retain=2
snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' | while read -r name rev; do
  echo "  gỡ $name (rev $rev)"; snap remove "$name" --revision="$rev" 2>&1 | sed 's/^/    /'
done

echo "== df SAU =="; df -h / | sed 's/^/  /'
echo "✅ Xong 3a (sudo). Báo lại để AI đo tổng dung lượng lấy lại."
