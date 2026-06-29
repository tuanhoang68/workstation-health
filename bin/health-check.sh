#!/usr/bin/env bash
# health-check.sh — quét + TỰ ĐÁNH GIÁ trạng thái máy → report markdown tự giải thích.
# Mỗi chỉ số có 🟢/🟡/🔴 + so baseline + khuyến nghị. Không cần sudo.
# Dùng: health-check.sh [nhãn]
# Ngưỡng: xem docs/health-check-guide.md (nguồn chân lý). Baseline: 2026-06-28.
set -uo pipefail
WS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL="${1:-periodic}"; TS="$(date +%Y-%m-%d_%H%M%S)"
# Mỗi lần health = 1 thư mục health/<thời-gian>-<nhãn>/ (cổng vào; optimization nằm trong nếu cần)
RUNDIR="$WS/health/${TS}-${LABEL}"; mkdir -p "$RUNDIR"; OUT="$RUNDIR/report.md"
exec > >(tee "$OUT") 2>&1

WARN=(); CRIT=()   # gom cảnh báo
add_warn(){ WARN+=("$1"); }; add_crit(){ CRIT+=("$1"); }
# flag <giá trị số> <green_max> <yellow_max>  → in 🟢/🟡/🔴 (giá trị càng cao càng xấu)
flag(){ awk -v v="$1" -v g="$2" -v y="$3" 'BEGIN{ if(v<=g)print"🟢"; else if(v<=y)print"🟡"; else print"🔴" }'; }

# ----- THU THẬP -----
DISKPCT=$(df / | awk 'END{gsub("%","",$5);print $5}')
DISKAVAIL=$(df -h / | awk 'END{print $4}')
PSIMEM=$(awk '/^some/{for(i=1;i<=NF;i++)if($i~/avg300/){split($i,a,"=");print a[2]}}' /proc/pressure/memory)
SWAPIMG=$(swapon --show=NAME,USED --noheadings 2>/dev/null | awk '/swap.img/{print $2}')
ZRAM=$(zramctl --noheadings 2>/dev/null | awk '{print $1}' | grep -c zram0)
SWAPPINESS=$(cat /proc/sys/vm/swappiness)
PROFILE=$(powerprofilesctl get 2>/dev/null || echo "?")
NOATIME=$(mount | grep ' / ' | grep -oE 'noatime' | head -1)
TEMP=$(sensors 2>/dev/null | awk '/Package id 0/{gsub(/[+°C]/,"",$4);print $4}')
THROTTLE=$(for c in 0 1 2 3; do cat /sys/devices/system/cpu/cpu$c/thermal_throttle/core_throttle_count 2>/dev/null; done | paste -sd+ | bc 2>/dev/null)
BAT=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null); BATH=$(awk 'BEGIN{ef='"$(cat /sys/class/power_supply/BAT0/energy_full 2>/dev/null||echo 0)"'; ed='"$(cat /sys/class/power_supply/BAT0/energy_full_design 2>/dev/null||echo 1)"'; if(ed>0)printf"%.0f",ef/ed*100}')
INOTIFY=$(cat /proc/sys/fs/inotify/max_user_watches)
GOCACHE_SZ=$(du -sh "$(go env GOCACHE 2>/dev/null)" 2>/dev/null | cut -f1)

# ----- ĐÁNH GIÁ -----
fDISK=$(flag "$DISKPCT" 75 88); [ "$fDISK" = "🟡" ] && add_warn "Disk $DISKPCT% — nên dọn (.cache trừ go-build, snap cũ)"; [ "$fDISK" = "🔴" ] && add_crit "Disk $DISKPCT% — dọn GẤP"
fPSI=$(flag "${PSIMEM:-0}" 5 20); [ "$fPSI" = "🔴" ] && add_crit "PSI memory ${PSIMEM}% kéo dài — thiếu RAM thật"
fTEMP=$(flag "${TEMP:-0}" 90 95); [ "$fTEMP" = "🔴" ] && add_crit "Nhiệt ${TEMP}°C cao — kiểm tra keo/quạt"
[ "$ZRAM" = "1" ] && fZRAM="🟢" || { fZRAM="🔴"; add_crit "MẤT zram — chạy: sudo systemctl restart zramswap"; }
[ "$PROFILE" = "performance" ] && fPROF="🟢" || { fPROF="🟡"; add_warn "Profile=$PROFILE (không phải performance) — chạy: systemctl --user start set-performance-profile"; }
[ -n "$NOATIME" ] && fNOA="🟢" || { fNOA="🟡"; add_warn "Mất noatime trên / — kiểm tra /etc/fstab"; }
[ "${SWAPPINESS}" = "180" ] && fSWP="🟢" || fSWP="🟡"

kv(){ printf -- '| %s | %s | %s |\n' "$1" "$2" "$3"; }

# ----- REPORT -----
echo "# 🩺 Health check — $TS ($LABEL)"
echo "> Máy: $(hostname) · $(. /etc/os-release; echo "$PRETTY_NAME") · kernel $(uname -r) · uptime $(uptime -p)"
echo "> Baseline so sánh: **2026-06-28** (sau tối ưu Tier 1–5). Ngưỡng: \`docs/health-check-guide.md\`."
echo "> Phần cứng (bất biến): \`docs/machine-specs.md\` — file này CHỈ báo cáo trạng thái."

echo; echo "## 🚦 Tổng kết"
if [ ${#CRIT[@]} -eq 0 ] && [ ${#WARN[@]} -eq 0 ]; then
  echo "**🟢 TẤT CẢ BÌNH THƯỜNG** — không có cảnh báo. Máy đang ở trạng thái chuẩn sau tối ưu."
else
  [ ${#CRIT[@]} -gt 0 ] && { echo "**🔴 CẦN XỬ LÝ (${#CRIT[@]}):**"; for w in "${CRIT[@]}"; do echo "- $w"; done; }
  [ ${#WARN[@]} -gt 0 ] && { echo "**🟡 LƯU Ý (${#WARN[@]}):**"; for w in "${WARN[@]}"; do echo "- $w"; done; }
fi

echo; echo "## Chỉ số chính (so baseline + đánh giá)"
echo "| Chỉ số | Hiện tại | Trạng thái |"; echo "|---|---|---|"
kv "Disk \`/\` dùng" "$DISKPCT% (trống $DISKAVAIL) · baseline 49%" "$fDISK"
kv "PSI memory avg300" "${PSIMEM}% · baseline ~0" "$fPSI"
kv "zram" "$([ "$ZRAM" = 1 ] && zramctl --noheadings | awk '{print $1" "$4"/"$5}' || echo 'KHÔNG CÓ')" "$fZRAM"
kv "swappiness" "$SWAPPINESS · chuẩn 180" "$fSWP"
kv "Swap /swap.img (SSD)" "${SWAPIMG:-0} dùng" "🟢"
kv "Power profile" "$PROFILE · chuẩn performance" "$fPROF"
kv "noatime trên /" "${NOATIME:-KHÔNG}" "$fNOA"
kv "Nhiệt (nhàn rỗi)" "${TEMP}°C · *sustained đo bằng \`bench.sh cpu\`*" "$fTEMP"
kv "Throttle count" "${THROTTLE:-?} · baseline 4" "🟢"
kv "inotify watches" "$INOTIFY · chuẩn 524288" "$([ "$INOTIFY" -ge 524288 ] 2>/dev/null && echo 🟢 || echo 🟡)"
kv "GOCACHE (build Go)" "${GOCACHE_SZ:-?} · phải GIỮ ấm" "🟢"
kv "Pin (theo dõi)" "health ~${BATH}% · ${BAT}% sạc" "$(flag "$((100-${BATH:-100}))" 50 70)"

echo; echo "## Chi tiết"
echo '```'; free -h; echo; echo "Swap:"; swapon --show 2>/dev/null; echo; echo "PSI memory:"; cat /proc/pressure/memory
echo; echo "Top RAM:"; ps -eo pmem,rss,comm --sort=-rss 2>/dev/null | head -6; echo '```'

echo; echo "## ➡️ Bước tiếp theo (flow)"
if [ ${#CRIT[@]} -eq 0 ] && [ ${#WARN[@]} -eq 0 ]; then
  echo "- 🟢 **Mọi thứ bình thường → KẾT THÚC flow.** Giữ report này làm mốc lịch sử, không cần làm gì."
else
  echo "- ⚠️ **Có cờ — flow tiếp tục (cần phán đoán, KHÔNG tự động):**"
  echo "  1. (tùy chọn) chạy \`bin/bench.sh cpu|ram|disk\` để khẳng định vấn đề dưới tải."
  echo "  2. Nếu quyết định tối ưu → tạo đợt *bên trong* lần này:"
  echo "     \`cp -r _templates/optimization \"$RUNDIR/optimization\"\`"
  echo "  3. Theo flow tối ưu: design → chạy tweak (\`tweaks/*.sh\`, có --rollback) → đo before/after → ghi \`optimization/steps/\` → cập nhật \`optimization/tracker.md\` + \`docs/machine-optimization.md\`."
  echo "  - Cảnh báo cụ thể:"; for w in "${CRIT[@]}" "${WARN[@]}"; do echo "    - $w"; done
fi
echo; echo "_Report: $OUT · Flow & hướng dẫn: docs/health-check-guide.md · Phần cứng: docs/machine-specs.md_"
