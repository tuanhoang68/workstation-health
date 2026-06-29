#!/usr/bin/env bash
# tweaks/tier2a-inotify.sh — Bước 2a: nâng trần inotify cho IDE/file-watcher
# Chạy: sudo bash tweaks/tier2a-inotify.sh   |   Rollback: ... --rollback
set -euo pipefail
CONF=/etc/sysctl.d/99-workstation-ide.conf
if [ "$(id -u)" -ne 0 ]; then echo "❌ Cần sudo: sudo bash $0"; exit 1; fi

if [ "${1:-}" = "--rollback" ]; then
  rm -f "$CONF"; sysctl --system >/dev/null
  echo "Đã xóa $CONF. Hiện tại: watches=$(sysctl -n fs.inotify.max_user_watches) instances=$(sysctl -n fs.inotify.max_user_instances)"
  exit 0
fi

echo "== TRƯỚC: watches=$(sysctl -n fs.inotify.max_user_watches) instances=$(sysctl -n fs.inotify.max_user_instances) =="
cat > "$CONF" <<'EOF'
# Tier 2a — inotify cho IDE (workstation-health)
fs.inotify.max_user_watches=524288    # IDE theo dõi đủ file lớn → hết "watch limit", reload nhanh
fs.inotify.max_user_instances=256     # nhiều tool watch song song (IDE + CLI) không đụng trần
EOF
cat "$CONF"
sysctl --system >/dev/null
echo "== SAU: watches=$(sysctl -n fs.inotify.max_user_watches) instances=$(sysctl -n fs.inotify.max_user_instances) =="
echo "✅ Xong 2a."
