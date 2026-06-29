# workstation-health

Workspace quản lý sức khỏe & tối ưu hiệu năng **ThinkBook 14+ G6** (máy dev Go chính).
Đặt trong `~/GolandProjects/`. Mọi thay đổi đều **có số đo before/after** và **rollback được**.

## Bắt đầu nhanh
```bash
cd ~/GolandProjects/workstation-health
bin/health-check.sh            # quét + tự đánh giá 🟢/🟡/🔴 → health/<lần>/report.md
```
Đọc report: xem mục **🚦 Tổng kết**. Cách diễn giải đầy đủ: **`docs/health-check-guide.md`**.

## Cấu trúc
```
workstation-health/
├── README.md                       # file này — bản đồ workspace
├── bin/                            # CÔNG CỤ đo/quét (chạy thường xuyên, không đổi hệ thống)
│   ├── health-check.sh             # quét + tự đánh giá → health/<lần>/report.md
│   ├── bench.sh                    # tải chuẩn đo before/after: cpu|ram|disk|go <dir>
│   ├── verify-after-reboot.sh      # kiểm mọi tweak có dính sau reboot
│   └── probe-specs.sh              # (sudo) lấy thông số phần cứng → machine-specs
├── tweaks/                         # SCRIPT ÁP TWEAK tái dùng (xuyên đợt, đều có --rollback)
│   ├── tier1a-zram.sh   tier1b-sysctl.sh   tier2a-inotify.sh
│   └── tier3a-cleanup-user.sh   tier3a-cleanup-sudo.sh   tier3b-noatime.sh
├── docs/                           # TÀI LIỆU xuyên suốt (không gắn 1 lần nào)
│   ├── machine-specs.md            # 🔧 phần cứng BẤT BIẾN (CPU/RAM/SSD/…)
│   ├── health-check-guide.md       # ⭐ hướng dẫn + ngưỡng + checklist (người & Claude)
│   ├── machine-optimization.md     # doc sống: cấu hình chuẩn + nhật ký tweak + rollback
│   └── knowledge/                  # 📚 kiến thức tham khảo (vd: cron vs systemd timer)
├── _templates/                     # 🧩 KHUÔN: health-run/ và optimization/ (copy ra khi cần)
└── health/                         # 📁 MỖI LẦN HEALTH = 1 thư mục (cổng vào, chạy TRƯỚC)
    └── <ngày-nhãn>/
        ├── report.md               #   health check (LUÔN có, quyết định)
        ├── bench/                  #   (nếu đo tải)
        └── optimization/           #   (NẾU health quyết định cần tối ưu)
            ├── README.md · design.md · tracker.md
            └── steps/step-*.md     #   bằng chứng từng bước
```

**Triết lý:** **health luôn chạy TRƯỚC và quyết định optimization** → optimization nằm *bên trong* lần health sinh ra nó (cron cũng vậy). `docs/` = bất biến/xuyên suốt · `health/<lần>/` = mỗi lần đo + tối ưu kèm theo · `tweaks/` = script tái dùng.

## Script nào dùng khi nào
| Script | Khi nào | Sudo? |
|---|---|---|
| `health-check.sh [nhãn]` | định kỳ / trước-sau thay đổi / nghi bất thường | không |
| `bench.sh cpu` | đo nhiệt + freq bền dưới tải | không |
| `bench.sh ram` | đo hành vi swap/PSI khi thiếu RAM | không |
| `bench.sh disk` | đo tốc độ đĩa | không |
| `bench.sh go <dir>` | đo thời gian build Go | không |
| `tweaks/tier1a-zram.sh` … | (đã áp) tweak từng tier · gỡ bằng `--rollback` | **có** |
| `verify-after-reboot.sh` | sau mỗi lần reboot | không |
| `bin/probe-specs.sh` | cập nhật `machine-specs.md` khi đổi phần cứng | **có** |

## Nguyên tắc (xem chi tiết trong guide § AI onboarding)
- Từng bước nhỏ có checkpoint · bằng chứng thực nghiệm · không sudo tự động (soạn script cho user) · mọi tweak rollback được · pin bỏ qua (luôn cắm sạc).

## Tình trạng tối ưu
> ℹ️ Các lần health/optimization **thật** nằm trong `health/<ngày-nhãn>/` nhưng đã được `.gitignore`
> (trạng thái cá nhân của máy — không đẩy lên public). Xem `health/demo/report.md` để hình dung output.
> Cấu hình chuẩn + rollback tổng (commit): `docs/machine-optimization.md`.
