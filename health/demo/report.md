# 🩺 Health check — DEMO (weekly)

> ⚠️ **Đây là bản DEMO đã làm sạch** — số liệu minh hoạ để hình dung output của `bin/health-check.sh`.
> Các lần health thật nằm ở `health/<ngày-nhãn>/` và đã được `.gitignore` (trạng thái cá nhân của máy).
>
> Máy: ThinkBook-14+-G6 · Ubuntu 24.04 LTS · kernel 6.x · uptime <ví dụ>
> Baseline so sánh: **lần tối ưu gần nhất**. Ngưỡng: `docs/health-check-guide.md`.

## 🚦 Tổng kết
**🟢 TẤT CẢ BÌNH THƯỜNG** — không có cảnh báo. (Ví dụ trạng thái chuẩn sau tối ưu.)

## Chỉ số chính (so baseline + đánh giá)
| Chỉ số | Hiện tại | Trạng thái |
|---|---|---|
| Disk `/` dùng | 47% (trống 119G) · baseline 49% | 🟢 |
| PSI memory avg300 | 0.00% · baseline ~0 | 🟢 |
| zram | /dev/zram0 437M/100M | 🟢 |
| swappiness | 180 · chuẩn 180 | 🟢 |
| Swap /swap.img (SSD) | 0B dùng | 🟢 |
| Power profile | performance · chuẩn performance | 🟢 |
| noatime trên / | noatime | 🟢 |
| Nhiệt (nhàn rỗi) | ~79°C · *sustained đo bằng `bench.sh cpu`* | 🟢 |
| Throttle count | 0 · baseline 4 | 🟢 |
| inotify watches | 524288 · chuẩn 524288 | 🟢 |
| GOCACHE (build Go) | ~3G · phải GIỮ ấm | 🟢 |
| Pin (theo dõi) | health ~36% (luôn cắm sạc → bỏ qua) | 🟡 |

## Chi tiết
```
               total        used        free      shared  buff/cache   available
Mem:            15Gi       9.9Gi       815Mi       2.1Gi       7.2Gi       5.5Gi
Swap:           11Gi       487Mi        11Gi

PSI memory:
some avg10=0.00 avg60=0.00 avg300=0.00
full avg10=0.00 avg60=0.00 avg300=0.00

Top RAM (ví dụ):
%MEM   RSS COMMAND
14.7  ...  <ide>
 5.9  ...  <browser>
 3.1  ...  <app>
```

## ➡️ Bước tiếp theo (flow)
- 🟢 **Mọi thứ bình thường → KẾT THÚC flow.** Giữ report làm mốc lịch sử, không cần làm gì.

_Demo · Flow & hướng dẫn: docs/health-check-guide.md · Phần cứng: docs/machine-specs.md_
