#!/usr/bin/env bash
# tweaks/tier1b-sysctl.sh — Bước 1b: sysctl RAM tuning (có zram nên swappiness CAO)
# Chạy: sudo bash tweaks/tier1b-sysctl.sh
# Rollback: sudo bash tweaks/tier1b-sysctl.sh --rollback
set -euo pipefail
CONF=/etc/sysctl.d/99-workstation-ram.conf

if [ "$(id -u)" -ne 0 ]; then echo "❌ Cần sudo: sudo bash $0"; exit 1; fi

if [ "${1:-}" = "--rollback" ]; then
  echo "== ROLLBACK sysctl RAM tuning =="
  rm -f "$CONF"
  sysctl --system >/dev/null
  echo "Đã xóa $CONF, nạp lại giá trị mặc định. Giá trị hiện tại:"
  for k in vm.swappiness vm.vfs_cache_pressure vm.dirty_ratio vm.dirty_background_ratio; do
    echo "  $k = $(sysctl -n $k)"; done
  exit 0
fi

echo "== Giá trị TRƯỚC =="
for k in vm.swappiness vm.vfs_cache_pressure vm.dirty_ratio vm.dirty_background_ratio; do
  echo "  $k = $(sysctl -n $k)"; done

echo "== Ghi $CONF =="
cat > "$CONF" <<'EOF'
# Tier 1b — RAM tuning cho máy có zram (workstation-health)
vm.swappiness=180            # có zram (nén ~4.6x, ghi SSD ~0) → đẩy trang nguội vào zram sớm
vm.vfs_cache_pressure=50     # giữ cache inode/dentry lâu hơn → mở file/ls/git nhanh hơn
vm.dirty_ratio=10            # flush sớm hơn, tránh dồn ghi lớn gây khựng trên SSD
vm.dirty_background_ratio=5
EOF
cat "$CONF"

echo "== Nạp =="
sysctl --system >/dev/null

echo "== Giá trị SAU =="
for k in vm.swappiness vm.vfs_cache_pressure vm.dirty_ratio vm.dirty_background_ratio; do
  echo "  $k = $(sysctl -n $k)"; done
echo
echo "✅ Xong bước 1b. Báo lại để AI chạy bench đo 'sau'."
