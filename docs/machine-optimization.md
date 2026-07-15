# Doc sống — Cấu hình chuẩn & Nhật ký tweak

> Nơi tra cứu: **đã đổi gì, giá trị chuẩn, cách hoàn tác**. Cập nhật mỗi khi áp/gỡ tweak.
> Doc XUYÊN ĐỢT (cấu hình chuẩn + rollback mọi tweak). Bằng chứng từng đợt: `health/<lần>/optimization/`

## Cấu hình chuẩn hiện hành (sau fix 2026-07-15)

| Hạng mục | Giá trị chuẩn | File/cơ chế |
|---|---|---|
| zram | lz4, ~7.7GB (PERCENT=50), prio 100 | `/etc/default/zramswap` + service `zramswap` |
| swappiness | 180 | `/etc/sysctl.d/99-workstation-ram.conf` |
| vfs_cache_pressure | 50 | nt |
| dirty_ratio / background | 10 / 5 | nt |
| OOM protection | systemd-oomd (KHÔNG earlyoom) | sẵn có |
| inotify watches / instances | 524288 / 256 | `/etc/sysctl.d/99-workstation-ide.conf` |
| Mount `/` | `noatime` (live via remount) | `/etc/fstab` ⚠️ **chưa ghi — xem mục Việc còn lại** |
| fstrim | timer enabled/active | systemd |
| Power profile | performance | `powerprofilesctl` _(cơ chế dính sau reboot chưa xác nhận — không có user service)_ |
| GOCACHE | `~/.cache/go-build` — GIỮ ấm, đừng xoá | — |
| GoLand Xmx | mặc định (chưa override) | không có `goland64.vmoptions` |
| Health check timer | **chưa bật** | — |

## Nhật ký tweak + lệnh rollback

### Fix 2026-07-15 — Restore standard config (từ health check `2026-07-15_085515-manual-claude`)

**Vấn đề phát hiện:** swappiness=10 · inotify=65536 · noatime mất · disk 88%.

**Kết quả disk cleanup:**
| Nguồn | Trước | Sau |
|---|---|---|
| Chrome cache | 3.0G | 0 |
| JetBrains 2025.2+2025.3 (cũ) | 3.3G | 0 |
| npm cache | 5.4G | 0 |
| thumbnails + mesa shader | ~120M | 0 |
| journal logs | 3.9G | 200M |
| apt archives | 825M | 0 |
| snap revisions cũ | ~(nhiều) | 0 |
| **Tổng lấy lại** | **~16G** | |
| **Disk sau** | 88% (29G free) | **81% (45G free)** |

> Disk 81% là sàn thực tế: thư mục dữ liệu lớn người dùng chiếm ~51G (không dọn được).

**Rollback từng tweak:**
- sysctl (swappiness): `sudo bash tweaks/tier1b-sysctl.sh --rollback`
- inotify: `sudo bash tweaks/tier2a-inotify.sh --rollback`
- noatime: `sudo bash tweaks/tier3b-noatime.sh --rollback`
- disk cleanup: không rollback được (cache, an toàn)

## Việc còn lại / tùy chọn

- [ ] **⚠️ fstab noatime chưa ghi** — noatime đang live nhưng sẽ mất sau reboot. Cần chạy:
  ```bash
  sudo sed -i 's|ext4    errors=remount-ro|ext4    errors=remount-ro,noatime|' /etc/fstab
  grep ' / ' /etc/fstab   # verify
  ```
- [ ] **Power profile sau reboot** — hiện tại `performance` nhưng không có user service `set-performance-profile`. Cần kiểm tra sau reboot xem có giữ không. Nếu không: tạo user service tương tự như tweaks gốc.
- [ ] **Health-check timer** — chưa bật. Để bật hàng tuần:
  ```bash
  # tạo ~/.config/systemd/user/health-check.service + health-check.timer rồi:
  systemctl --user enable --now health-check.timer
  ```
- [ ] (tùy chọn) Override GoLand heap: nếu GoLand thấy ì/OOM, tạo `~/.config/JetBrains/GoLand2026.1/goland64.vmoptions` với `-Xmx2560m`.
- [ ] (tùy chọn) Xác nhận loại RAM bằng `sudo bash bin/probe-specs.sh`.
- [ ] Verify sau reboot tự nhiên tiếp theo: `bin/verify-after-reboot.sh`.
