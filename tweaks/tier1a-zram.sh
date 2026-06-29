#!/usr/bin/env bash
# tweaks/tier1a-zram.sh — Bước 1a: bật zram (zram-tools, zstd, ~8GB, prio > /swap.img)
# Chạy: sudo bash tweaks/tier1a-zram.sh
# Rollback: sudo bash tweaks/tier1a-zram.sh --rollback
set -euo pipefail

CONF=/etc/default/zramswap

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Cần chạy bằng sudo:  sudo bash $0"; exit 1
fi

if [ "${1:-}" = "--rollback" ]; then
  echo "== ROLLBACK zram =="
  systemctl stop zramswap 2>/dev/null || true
  systemctl disable zramswap 2>/dev/null || true
  apt-get remove -y zram-tools || true
  [ -f "$CONF.bak-tier1a" ] && mv "$CONF.bak-tier1a" "$CONF" && echo "đã khôi phục $CONF"
  echo "== trạng thái sau rollback =="; swapon --show; zramctl 2>/dev/null || echo "(zram đã tắt)"
  exit 0
fi

echo "== [1/4] Cài zram-tools =="
apt-get install -y zram-tools

echo "== [2/4] Ghi cấu hình $CONF =="
[ -f "$CONF" ] && cp -n "$CONF" "$CONF.bak-tier1a" && echo "đã backup -> $CONF.bak-tier1a"
cat > "$CONF" <<'EOF'
# Tier 1a — zram tuning (workstation-health)
ALGO=zstd          # nén tốt, CPU thừa sức
PERCENT=50         # zram ~8GB (50% của 16GB RAM)
PRIORITY=100       # zram ưu tiên TRƯỚC /swap.img (prio -2)
EOF
cat "$CONF"

echo "== [3/4] Khởi động lại service zramswap =="
systemctl restart zramswap
systemctl enable zramswap 2>/dev/null || true

echo "== [4/4] Xác nhận =="
echo "--- zramctl ---"; zramctl
echo "--- swapon --show ---"; swapon --show
echo
echo "✅ Xong bước 1a. /swap.img vẫn còn làm fallback (không xóa)."
echo "   Báo lại để AI chạy bench đo 'sau'."
