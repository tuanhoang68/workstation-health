#!/usr/bin/env bash
# verify-after-reboot.sh — kiểm tra mọi tweak có DÍNH sau reboot không. Không cần sudo.
set -uo pipefail
pass=0; fail=0
chk() { # chk "tên" "giá trị thực" "kỳ vọng (regex)"
  if echo "$2" | grep -qE "$3"; then echo "  ✅ $1: $2"; pass=$((pass+1));
  else echo "  ❌ $1: $2 (cần khớp: $3)"; fail=$((fail+1)); fi
}
echo "== VERIFY SAU REBOOT — $(date +%H:%M:%S) =="
chk "zram active"        "$(zramctl --noheadings 2>/dev/null | awk '{print $1}')" "zram0"
chk "zram prio 100"      "$(swapon --show=NAME,PRIO --noheadings 2>/dev/null | awk '/zram0/{print $2}')" "^100$"
chk "swappiness=180"     "$(cat /proc/sys/vm/swappiness)"                          "^180$"
chk "vfs_cache_pressure=50" "$(cat /proc/sys/vm/vfs_cache_pressure)"               "^50$"
chk "dirty_ratio=10"     "$(cat /proc/sys/vm/dirty_ratio)"                         "^10$"
chk "inotify watches"    "$(cat /proc/sys/fs/inotify/max_user_watches)"            "524288"
chk "noatime on /"       "$(mount | grep ' / ' | grep -oE 'noatime' | head -1)"    "noatime"
chk "power profile"      "$(powerprofilesctl get 2>/dev/null)"                     "performance"
chk "perf-profile service" "$(systemctl --user is-enabled set-performance-profile.service 2>/dev/null)" "enabled"
# GoLand heap — đọc từ idea.log (bản snap giấu -Xmx khỏi cmdline)
GLOG=$(ls -t ~/.cache/JetBrains/GoLand*/log/idea.log 2>/dev/null | head -1)
if [ -n "$GLOG" ]; then
  xmx=$(grep -a "JVM options" "$GLOG" | tail -1 | grep -oE '\-Xmx[0-9]+m' | tail -1)
  chk "GoLand -Xmx (idea.log)" "${xmx:-?}" "Xmx2560m"
else
  echo "  ⏳ chưa thấy idea.log — mở GoLand một lần rồi chạy lại"
fi
echo
echo "== sustained freq (ép 8 luồng 8s, xác nhận full power) =="
for i in $(seq 8); do timeout 8 bash -c 'while :; do a=$((a*a+1)); done' & done
sleep 6; echo "  freq tb: $(grep MHz /proc/cpuinfo | awk '{s+=$4;n++}END{printf "%.0f MHz",s/n}') · nhiệt: $(sensors 2>/dev/null|awk '/Package id 0/{print $4}')"
wait 2>/dev/null
echo
echo "== KẾT QUẢ: $pass đạt / $fail lỗi =="
