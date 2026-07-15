# Hướng dẫn Health Check định kỳ — workstation-health

> **File này cho 2 đối tượng đọc:**
> - 👤 **Người dùng (bạn):** biết khi nào chạy, đọc report thế nào, làm gì khi có cờ đỏ.
> - 🤖 **Claude (session sau):** đọc mục "AI onboarding" để nắm ngay bối cảnh & quy tắc.
>
> Máy: **HP Slim Desktop S01-pF2xxx** · i3-12100 · 16GB · ~238GB NVMe · Ubuntu 22.04 / kernel 6.8.x.
> Baseline chuẩn: **2026-07-15** (sau fix lần đầu). Pin 🔴 = bình thường — desktop, không có pin.

---

## 0. Flow tổng thể (đọc trước)

**Nguyên tắc:** HEALTH luôn chạy trước & quyết định. `health-check.sh` tự động **toàn bộ nhánh health**.
Nhánh **optimization KHÔNG tự chạy** (cần phán đoán + sudo + rollback) — do người/Claude quyết.

```
   ┌──────────────────────────────────────────────┐
   │ Kích hoạt: định kỳ (cron) · nghi máy ì ·      │
   │ trước/sau thay đổi lớn · sau update kernel     │
   └───────────────────────┬──────────────────────┘
                           ▼
            $ bin/health-check.sh [nhãn]            ◄── 1 LỆNH, tự động hết nhánh health
                           │   quét → đánh giá ngưỡng → verdict
                           ▼
        health/<ngày-nhãn>/report.md   (LUÔN sinh; tự có 🟢/🟡/🔴 + khuyến nghị)
                           │
                    ┌──────┴───────┐
              🟢 sạch │              │ 🟡/🔴 có cờ đỏ
                     ▼              ▼
              ┌────────────┐   (tùy chọn) bin/bench.sh cpu|ram|disk
              │ KẾT THÚC.  │   khẳng định dưới tải
              │ Lưu mốc.   │        │
              └────────────┘        ▼
                            Quyết định: có tối ưu không?  ──(không)──► kết thúc, theo dõi
                                     │ có
                                     ▼
                    cp -r _templates/optimization  health/<lần>/optimization
                                     │
                                     ▼
                    design.md → chạy tweaks/*.sh (sudo, có --rollback)
                    → đo before/after → steps/step-*.md → tracker.md
                                     │
                                     ▼
                    verify (reboot nếu cần: bin/verify-after-reboot.sh)
                    → cập nhật docs/machine-optimization.md (nhật ký + rollback)
```

**Tóm tắt cho người:** chạy 1 lệnh → đọc verdict. 🟢 thì xong; 🟡/🔴 thì report tự ghi "Bước tiếp theo".
**Tóm tắt cho Claude:** chỉ `health-check.sh` là tự động; mọi bước đổi hệ thống phải qua nhánh optimization
thủ công (template + tweak script cho user chạy sudo). Xem mục 6 (AI onboarding) cho quy tắc.

---

## 1. Khi nào chạy health check
- **Định kỳ:** hàng tuần **TỰ ĐỘNG** (user timer `health-check.timer`, Mon 10:00, Persistent — đã bật 2026-06-28) → sinh `health/<ts>-weekly/report.md`.
  - Quản lý: `systemctl --user list-timers` (xem lịch) · `systemctl --user status/start/disable health-check.timer`.
  - Máy tắt đúng giờ hẹn? `Persistent=true` sẽ chạy bù ở lần bật/đăng nhập kế. (Muốn chạy cả khi chưa đăng nhập: `loginctl enable-linger $USER` — tùy chọn.)
  - Report tích nhiều dần: giữ mốc + ~8 bản gần nhất, xoá `health/*-weekly/` cũ khi cần (an toàn vì chỉ là snapshot).
- **Thủ công khi:** máy thấy ì/giật · trước & sau khi cài/gỡ thứ lớn · sau update kernel · sau khi dọn disk · nghi pin/nhiệt bất thường.

## 2. Cách chạy
```bash
cd ~/GolandProjects/workstation-health
bin/health-check.sh [nhãn]        # vd: bin/health-check.sh sau-update-kernel
```
→ Sinh **thư mục** `health/<thời-gian>-<nhãn>/` chứa `report.md` (tự in 🟢/🟡/🔴 + so baseline + khuyến nghị).
Đo dưới tải (tùy chọn): `bin/bench.sh cpu` (nhiệt/freq bền) · `bin/bench.sh ram` (swap/PSI) · `bin/bench.sh disk`.

> **Mô hình thư mục:** health luôn chạy TRƯỚC và quyết định optimization. Mỗi lần health = 1 thư mục
> `health/<lần>/` (cổng vào). **Nếu** health cho thấy cần tối ưu → tạo `optimization/` *bên trong* lần đó:
> `cp -r _templates/optimization health/<lần>/optimization`. Cron cũng theo đúng thứ tự này.

## 3. Cách đọc report
1. Xem mục **🚦 Tổng kết** đầu file: nếu "🟢 TẤT CẢ BÌNH THƯỜNG" → xong, lưu làm mốc.
2. Nếu có 🟡/🔴 → đọc danh sách + **Hành động đề xuất** (report tự gợi ý lệnh xử lý).
3. So cột "Hiện tại" với baseline ghi sẵn trong từng dòng.

## 4. 🚦 Bảng ngưỡng & cờ đỏ (NGUỒN CHÂN LÝ — script dùng đúng bảng này)

| Chỉ số | 🟢 OK | 🟡 Lưu ý | 🔴 Xử lý ngay | Nếu 🔴 làm gì |
|---|---|---|---|---|
| Disk `/` dùng | <75% | 75–88% | >88% | dọn `.cache` (trừ `go-build`), snap cũ: `tweaks/tier3a-cleanup-user.sh` |
| PSI memory avg300 | <5% | 5–20% | >20% kéo dài | đóng app ngốn RAM; kiểm tra zram còn sống |
| zram | có `/dev/zram0` prio100 | — | mất zram | `sudo systemctl restart zramswap` |
| swappiness | =180 | khác 180 | — | `sudo sysctl --system` (file 99-workstation-ram.conf) |
| Swap `/swap.img` (SSD) | ~ổn định/thấp | tăng dần | tăng nhanh liên tục | zram đầy/lỗi → kiểm `zramctl` |
| Power profile | performance | balanced/power-saver | — | `systemctl --user start set-performance-profile` |
| noatime trên `/` | có | mất | — | kiểm `/etc/fstab` (backup `.bak-tier3b`) |
| Nhiệt **sustained** (bench cpu) | <90°C | 90–95°C | >95°C | vệ sinh quạt / thay keo tản nhiệt |
| Throttle count | không tăng theo thời gian | tăng chậm | tăng nhanh | nhiệt/power → xem nhiệt + bench cpu |
| inotify watches | ≥524288 | thấp hơn | — | `sudo sysctl --system` (99-workstation-ide.conf) |
| GOCACHE go-build | còn (ấm) | — | bị xoá/0 | **đừng xoá** — build sẽ tụt về 46s; build lại để hâm |
| Pin (CHỈ theo dõi) | — | health giảm dần | sụt mạnh | phần cứng — luôn cắm sạc, không tuning |

> Pin luôn 🟡 và **không tính là cảnh báo** (đã chấp nhận: chai 35%, luôn cắm sạc).

## 5. Checklist bảo trì
- **Hàng tuần:** xem report tự động (timer). Nếu toàn 🟢 → bỏ qua.
- **Hàng tháng:** chạy thủ công 1 lần có nhãn; dọn cache nếu disk >75% (`tweaks/tier3a-cleanup-user.sh` — đã chừa go-build); liếc nhiệt sustained (`bench.sh cpu`).
- **Hàng quý:** `sudo fstrim -v /` thủ công; xem xu hướng pin/nhiệt qua các report cũ; cân nhắc **vệ sinh quạt + thay keo** nếu nhiệt sustained tăng dần.

---

## 6. 🤖 AI onboarding — đọc nếu bạn là Claude trong session mới

**Đây là gì:** workspace quản lý sức khỏe & tối ưu máy dev Go **HP Slim Desktop S01-pF2xxx** của user.

**Phần cứng chốt nhanh:** i3-12100 (4C/8T, max 4.3GHz) · 16GB RAM · 238GB NVMe · Intel UHD 730 · Ubuntu 22.04 LTS · kernel 6.8.x · **desktop — không có pin** (Pin 🔴 trong health-check là bình thường, bỏ qua).

**Quy tắc làm việc với user này (BẮT BUỘC):**
1. **Từng bước nhỏ, có checkpoint** — làm 1 phần → đo → trình → chờ user duyệt GIỮ/ROLLBACK. Không gộp nhiều bước rủi ro.
2. **Bằng chứng thực nghiệm, không lý thuyết** — mọi tuyên bố "nhanh hơn/tốt hơn" phải có số đo before/after thật.
3. **Máy KHÔNG có sudo không mật khẩu** → KHÔNG tự chạy `sudo`. Soạn script cho user tự chạy `sudo bash <script>`. Việc đọc/đo thì tự làm.
4. **Mọi tweak phải rollback được** — script có cờ `--rollback`.
5. Pin: **bỏ qua hoàn toàn** — desktop, không có pin, luôn có điện.

**Bản đồ nhanh:**
- `bin/health-check.sh` — quét + tự đánh giá (chạy trước/sau mọi thay đổi).
- `bin/bench.sh cpu|ram|disk|go <dir>` — tải chuẩn đo before/after.
- `tweaks/tier*.sh` — các tweak đã áp (có `--rollback`).
- `bin/verify-after-reboot.sh` — kiểm mọi tweak có dính sau reboot.
- `bin/probe-specs.sh` — (sudo) lấy thông số phần cứng chi tiết.
- `docs/machine-specs.md` — **phần cứng BẤT BIẾN** (CPU/RAM/SSD/màn/mạng…) — đọc để khỏi dò lại phần cứng.
- `docs/machine-optimization.md` — doc sống xuyên đợt: cấu hình chuẩn + nhật ký tweak + lệnh rollback + việc còn lại.
- `docs/knowledge/` — kiến thức tham khảo tích lũy.
- `health/<lần>/report.md` — health check từng lần · `health/<lần>/optimization/` — đợt tối ưu sinh từ lần đó.
- `_templates/` — khuôn health-run + optimization (copy ra khi cần).

**Trạng thái chuẩn (sau fix 2026-07-15):** zram zstd 7.7G prio100 · swappiness 180 · vfs_cache_pressure 50 · dirty 10/5 · inotify 524288 · noatime (fstab + live) · profile performance · disk ~81% (sàn thực tế, xem machine-optimization.md) · go-build cache bảo vệ · health timer bật. systemd-oomd lo OOM.

**Việc còn pending:** power profile sau reboot chưa verify — xem `docs/machine-optimization.md § Việc còn lại`.

**Disk 81% là bình thường** cho máy này — thư mục dữ liệu lớn người dùng ~51G. Chỉ cảnh báo nếu vượt 88%.

**Khi user nhờ "health check lại":** chạy `bin/health-check.sh`, đọc verdict, nếu có 🟡/🔴 thì điều tra theo bảng ngưỡng mục 4, đề xuất fix (soạn script sudo nếu cần). Đừng tự ý đổi cấu hình chuẩn nếu không có cờ đỏ.
