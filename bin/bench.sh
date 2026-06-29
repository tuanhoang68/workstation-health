#!/usr/bin/env bash
# bench.sh — tạo TẢI CHUẨN lặp lại được để đo before/after. Không cần sudo.
# Dùng:
#   bench.sh cpu            # ép 8 luồng 15s → freq/nhiệt/throttle
#   bench.sh ram            # tạo áp lực RAM AN TOÀN (tự dừng trước khi OOM) → swap/PSI
#   bench.sh disk           # dd seq + random (direct I/O)
#   bench.sh go <dir>       # time go build ./... (cold & warm) trong <dir>
#   bench.sh all            # cpu + disk (KHÔNG gồm ram để khỏi gây áp lực ngoài ý muốn)
set -uo pipefail

cmd="${1:-all}"
WS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

meminfo() { awk -v k="$1" '$1==k":"{print $2}' /proc/meminfo; }      # KB
vmctr()   { awk -v k="$1" '$1==k{print $2}' /proc/vmstat; }
psi()     { awk '/^some/{print $0}' /proc/pressure/"$1"; }
swapused(){ free -m | awk '/^Swap:/{print $3}'; }

bench_cpu() {
  echo "### CPU bench (8 luồng × 15s)"
  local t0; t0=$(for c in 0 1 2 3; do cat /sys/devices/system/cpu/cpu$c/thermal_throttle/core_throttle_count; done | paste -sd+ | bc)
  for i in $(seq 8); do timeout 15 bash -c 'while :; do a=$((a*a+1)); done' & done
  local maxf=0 sumf=0 n=0 maxt=0
  for s in 1 2 3; do
    sleep 4
    local f mf tp
    f=$(grep MHz /proc/cpuinfo | awk '{s+=$4;n++} END{printf "%.0f", s/n}')
    mf=$(grep MHz /proc/cpuinfo | awk 'BEGIN{m=0}{if($4>m)m=$4}END{printf "%.0f",m}')
    tp=$(sensors 2>/dev/null | awk '/Package id 0/{gsub(/[+°C]/,"",$4);print $4}')
    printf "  mốc %ds: avg %sMHz max %sMHz nhiệt %s°C\n" "$((s*4))" "$f" "$mf" "$tp"
    sumf=$((sumf+f)); n=$((n+1)); [ "$mf" -gt "$maxf" ] && maxf=$mf
    local tpi=${tp%.*}; [ "${tpi:-0}" -gt "$maxt" ] && maxt=$tpi
  done
  wait 2>/dev/null
  local t1; t1=$(for c in 0 1 2 3; do cat /sys/devices/system/cpu/cpu$c/thermal_throttle/core_throttle_count; done | paste -sd+ | bc)
  echo "  => sustained avg $((sumf/n))MHz · max ${maxf}MHz · nhiệt max ${maxt}°C · throttle Δ $((t1-t0))"
}

bench_ram() {
  echo "### RAM bench (áp lực có chốt an toàn)"
  local avail_mb floor target hold
  avail_mb=$(( $(meminfo MemAvailable)/1024 ))
  floor=600                                   # dừng cấp khi MemAvailable < 600MB
  target=$(( avail_mb + 2000 ))               # cố ý dấn ~2GB vào swap để quan sát
  hold=6
  echo "  MemAvailable trước: ${avail_mb}MB · target alloc: ${target}MB · floor an toàn: ${floor}MB"
  local pin0 pout0 su0; pin0=$(vmctr pswpin); pout0=$(vmctr pswpout); su0=$(swapused)
  echo "  PSI mem trước: $(psi memory)"
  echo "  PSI io  trước: $(psi io)"
  # cấp phát thích ứng bằng python3: theo chunk, tự dừng nếu chạm floor
  python3 - "$target" "$floor" "$hold" <<'PY'
import sys,time
target=int(sys.argv[1]); floor=int(sys.argv[2]); hold=int(sys.argv[3])
def avail():
    for l in open('/proc/meminfo'):
        if l.startswith('MemAvailable:'): return int(l.split()[1])//1024
chunks=[]; step=256
while sum(len(c) for c in chunks)//(1024*1024) < target:
    if avail() < floor:
        print(f"  [an toàn] dừng cấp: MemAvailable chạm floor"); break
    b=bytearray(step*1024*1024)
    for i in range(0,len(b),4096): b[i]=1     # chạm từng trang → resident
    chunks.append(b)
got=sum(len(c) for c in chunks)//(1024*1024)
print(f"  Đã cấp & chạm: {got}MB · giữ {hold}s")
time.sleep(hold)
PY
  sleep 1
  local pin1 pout1 su1; pin1=$(vmctr pswpin); pout1=$(vmctr pswpout); su1=$(swapused)
  echo "  PSI mem sau: $(psi memory)"
  echo "  PSI io  sau: $(psi io)"
  echo "  swap used: ${su0}MB → đỉnh ${su1}MB"
  echo "  => pswpout Δ $((pout1-pout0)) trang (~$(( (pout1-pout0)*4/1024 ))MB ghi swap) · pswpin Δ $((pin1-pin0)) trang"
  echo "  (sau bench, RAM tự giải phóng)"
}

bench_disk() {
  echo "### Disk bench (direct I/O)"
  local f="$WS/.bench.tmp"
  echo -n "  seq write 1GB: "; dd if=/dev/zero of="$f" bs=1M count=1024 oflag=direct 2>&1 | awk -F, 'END{print $NF}'
  echo -n "  seq read  1GB: "; dd if="$f" of=/dev/null bs=1M iflag=direct 2>&1 | awk -F, 'END{print $NF}'
  echo -n "  rand 4k×2000:  "; dd if=/dev/urandom of="$f" bs=4k count=2000 oflag=direct 2>&1 | awk -F, 'END{print $NF}'
  rm -f "$f"
}

bench_go() {
  local dir="${2:-}"; [ -z "$dir" ] && { echo "  cần: bench.sh go <dir>"; return 1; }
  cd "$dir" || return 1
  echo "### Go build bench ($dir)"
  echo -n "  cold (clean cache): "; go clean -cache 2>/dev/null; { /usr/bin/time -f "%e s" go build ./... ; } 2>&1 | tail -1
  echo -n "  warm:               "; { /usr/bin/time -f "%e s" go build ./... ; } 2>&1 | tail -1
}

case "$cmd" in
  cpu)  bench_cpu ;;
  ram)  bench_ram ;;
  disk) bench_disk ;;
  go)   bench_go "$@" ;;
  all)  bench_cpu; echo; bench_disk ;;
  *)    echo "Unknown: $cmd (dùng: cpu|ram|disk|go <dir>|all)"; exit 1 ;;
esac
