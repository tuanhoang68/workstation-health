# Doc sống — Cấu hình chuẩn & Nhật ký tweak (ThinkBook 14+ G6)

> Nơi tra cứu: **đã đổi gì, giá trị chuẩn, cách hoàn tác**. Cập nhật mỗi khi áp/gỡ tweak.
> Doc XUYÊN ĐỢT (cấu hình chuẩn + rollback mọi tweak). Bằng chứng từng đợt: `health/<lần>/optimization/`
> (vd đợt gần nhất `health/2026-06-28-machine-tuning/optimization/` — tracker.md + steps/).

## Cấu hình chuẩn hiện hành (sau Tier 1–5, 2026-06-28)

| Hạng mục | Giá trị chuẩn | File/cơ chế |
|---|---|---|
| zram | zstd, ~8GB (PERCENT=50), prio 100 | `/etc/default/zramswap` + service `zramswap` |
| swappiness | 180 | `/etc/sysctl.d/99-workstation-ram.conf` |
| vfs_cache_pressure | 50 | nt |
| dirty_ratio / background | 10 / 5 | nt |
| OOM protection | systemd-oomd (KHÔNG earlyoom) | sẵn có |
| inotify watches / instances | 524288 / 256 | `/etc/sysctl.d/99-workstation-ide.conf` |
| GoLand heap Xmx / Xms | 2560m / 256m | `~/.config/JetBrains/GoLand2026.1/goland64.vmoptions` |
| Mount `/` | `noatime` | `/etc/fstab` |
| fstrim | timer enabled | systemd |
| Power profile | performance (dính sau boot) | user service `set-performance-profile` |
| GOCACHE | `~/.cache/go-build` — GIỮ ấm, đừng xoá | — |

## Nhật ký tweak + lệnh rollback

### Tier 1 — RAM & Swap (✅ 2026-06-28)
- **zram** — kết quả: ghi SSD khi swap 3.1GB→3MB, nén 4.6×, PSI stall 37%→9%.
  - Rollback: `sudo bash tweaks/tier1a-zram.sh --rollback`
- **sysctl** (swappiness 180, vfs 50, dirty 10/5).
  - Rollback: `sudo bash tweaks/tier1b-sysctl.sh --rollback`
- **earlyoom**: KHÔNG cài (dùng systemd-oomd sẵn có).

### Tier 2 — IDE (✅ 2026-06-28)
- **inotify** 524288/256. Rollback: `sudo bash tweaks/tier2a-inotify.sh --rollback`
- **GoLand heap** 2048→2560 (file vmoptions custom; bỏ dòng debug go-indexing).
  - Rollback: xoá `~/.config/JetBrains/GoLand2026.1/goland64.vmoptions` rồi restart GoLand.
- **Exclude index**: để user tự Mark-as-Excluded trong IDE khi cần (không script).

### Tier 3 — Disk (✅ 2026-06-28)
- **Dọn ~35G** (65%→49%). Đã chừa `go-build` + `GoLand2026.1`. (Không rollback — đã xoá.)
- **noatime** (fstab). Rollback: `sudo bash tweaks/tier3b-noatime.sh --rollback` (backup `/etc/fstab.bak-tier3b`).
- **fstrim**: trim 126GiB (sẵn enabled).

### Tier 4 — Full power (✅ 2026-06-28)
- **Profile performance dính sau reboot** — user service.
  - Rollback: `systemctl --user disable --now set-performance-profile.service && powerprofilesctl set balanced`
- governor=performance & autostart: KHÔNG làm (có lý do — xem tracker).
- **Bảo trì vật lý: ✅ coi như DONE** (user xác nhận) — vệ sinh quạt + thay keo tản nhiệt.

### Tier 5 — Build Go (✅ điều tra 2026-06-28)
- Kết luận: warm build ~4s đã nhanh; cold 46–68s là CPU-bound compile-deps (không sửa bằng config).
  Đòn bẩy duy nhất = **giữ GOCACHE ấm** (đã bảo vệ ở Tier 3). cgo/tmpfs/GOAMD64 đo rồi, vô ích.
- **monorepo: BỎ khỏi phạm vi** (user quyết không tối ưu monorepo). *(Ghi chú kỹ thuật để tham khảo, KHÔNG phải việc cần làm: nếu sau này build monorepo bị fail sonic với go1.26 thì đặt `GOTOOLCHAIN=go1.22.7`.)*

## Việc còn lại / tùy chọn
- [x] Reboot tổng + `bin/verify-after-reboot.sh` → **10/10 ĐẠT** (mọi tweak dính, GoLand Xmx 2560, sustained 3245MHz). Đợt 2026-06-28 HOÀN TẤT.
- [x] **systemd timer health-check hằng tuần ĐÃ BẬT** (user timer `health-check.timer`, `OnCalendar=Mon 10:00`, Persistent). Mỗi tuần tự sinh `health/<ts>-weekly/report.md`. Quản lý: `systemctl --user {status,disable,start} health-check.timer` · xem lịch `systemctl --user list-timers`.
- [ ] (tùy chọn) đo công suất gói (W) bằng `sudo turbostat`.
- [x] (vật lý) vệ sinh quạt + thay keo — **coi như done** (user xác nhận).
