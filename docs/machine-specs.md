# Thông số phần cứng — ThinkBook 14+ G6 (BẤT BIẾN)

> File này chứa **thông tin phần cứng cố định** — KHÔNG phải trạng thái, KHÔNG cập nhật mỗi
> lần health check. Trạng thái/sức khỏe theo thời gian → xem `health/<lần>/report.md`.
> Cập nhật file này **chỉ khi đổi phần cứng** (thêm RAM, thay SSD, update BIOS…).
>
> Khi **đổi phần cứng** (RAM/SSD/BIOS…) → chạy lại `sudo bash bin/probe-specs.sh` và cập nhật.

## 1. Định danh máy
| | |
|---|---|
| Hãng / dòng | **Lenovo ThinkBook 14+ G6 IMH** |
| Model (MTM) | **21M0CTO1WW** (CTO = cấu hình đặt riêng) |
| Mainboard | LENOVO 21M0CTO1WW |
| BIOS/UEFI | **N3HET** series (UEFI), 2024 (Lenovo) |
| Serial / UUID | _(định danh máy → không lưu trong repo)_ |

## 2. CPU
| | |
|---|---|
| Model | **Intel Core Ultra 5 125H** @ 1.20GHz (base) |
| Vi kiến trúc | Meteor Lake-H (Core Ultra series 1) |
| Nhân / luồng | **14 nhân / 18 luồng** (4P + 8E + 2 LP-E), 1 socket |
| Xung | base ~1.2GHz · **turbo tối đa ~4.5GHz** · min 0.4GHz |
| TDP | 28W (base; cấu hình lên tới 64–115W) |
| Cache | L2 18MiB · **L3 18MiB** |
| Ảo hóa | VT-x (vmx, ept, vpid) |
| Tập lệnh đáng chú ý | **AVX2**, FMA, AES-NI, SSE4.1/4.2, RDRAND, BMI1/2, **HWP+EPP** |
| GOAMD64 hỗ trợ | tới **v3** (có AVX2) — *chỉ tăng tốc binary chạy, không tăng tốc compile* |

## 3. RAM
| | |
|---|---|
| Tổng | **16 GB** · usable ~15.4 GiB |
| Loại / tốc độ | **LPDDR5x-7467** (hàn cứng trên mainboard) |
| Kênh | **Dual channel** (on-board) |
| Nâng cấp | RAM hàn — **không nâng cấp được**, chọn dung lượng khi mua |

## 4. Lưu trữ
| | |
|---|---|
| SSD | **512 GB NVMe** (PCIe 4.0 ×4, M.2 2280), non-rotational |
| Phân vùng | `nvme0n1p1` 1G EFI (vfat) · `nvme0n1p2` ~475G ext4 (`/`, **noatime**) |
| SMART health | **PASSED** · Reallocated 0 · CRC errors 0 |
| Đặc tính đo | seq ~3000+ MB/s · rand4k nhanh (NVMe Gen4) |
| Lưu ý tuning | giảm ghi không cần thiết (zram, noatime); GOCACHE giữ ấm |

## 5. Đồ họa & màn hình
| | |
|---|---|
| GPU | **Intel Arc Graphics** (tích hợp, Meteor Lake) |
| Màn hình | eDP 14.5" · **2880×1800@120Hz** (2.8K, 16:10) |
| Framebuffer hiện tại | scaling ~200% (GNOME) |

## 6. Mạng
| | |
|---|---|
| Wi-Fi | **Intel Wi-Fi 6E AX211** (dual-band, BT combo) |
| Bluetooth | Intel BT 5.3 |
| Ethernet | không có cổng RJ45 (dùng USB-C dock nếu cần) |

## 7. Phần mềm nền (mốc, ít đổi)
| | |
|---|---|
| OS | **Ubuntu 24.04 LTS** (Noble Numbat) |
| Kernel | **6.x-generic** x86_64 |
| Init / Desktop / Session | systemd · **GNOME** · Wayland/X11 |
| Quản lý nguồn | power-profiles-daemon · systemd-oomd · thermald |

## 8. Bao bì nhiệt/điện (đặc tính tuning)
- Trần nhiệt: trip ~100°C — laptop mỏng, sustained phụ thuộc tản nhiệt.
- "Full power" đạt qua EPP performance + turbo on — tuning chủ yếu giữ cấu hình dính sau reboot.
- Pin ~75Wh; máy thường cắm sạc khi làm việc → bỏ qua pin khi tuning.
