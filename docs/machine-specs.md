# Thông số phần cứng — workstation (BẤT BIẾN)

> File này chứa **thông tin phần cứng cố định** — KHÔNG phải trạng thái, KHÔNG cập nhật mỗi
> lần health check. Trạng thái/sức khỏe theo thời gian → xem `health/<lần>/report.md`.
> Cập nhật file này **chỉ khi đổi phần cứng** (thêm RAM, thay SSD, update BIOS…).
>
> Khi **đổi phần cứng** → chạy lại `sudo bash bin/probe-specs.sh` và cập nhật.

## 1. Định danh máy

| | |
|---|---|
| Hãng / dòng | **HP Slim Desktop S01-pF2xxx** |
| Mainboard | HP 89B4 |
| Hostname | _(không lưu trong repo)_ |
| Serial / UUID | _(định danh máy → không lưu trong repo)_ |

## 2. CPU

| | |
|---|---|
| Model | **Intel Core i3-12100** (12th Gen Alder Lake) |
| Nhân / luồng | **4 nhân / 8 luồng** (4 P-cores + HT, không có E-cores hay LP-E) |
| Xung | min 800 MHz · **turbo tối đa 4300 MHz** |
| Cache | L1d 192 KiB · L1i 128 KiB · L2 5 MiB · **L3 12 MiB** |
| Ảo hóa | VT-x (vmx) |
| Tập lệnh đáng chú ý | **AVX2**, AVX-VNNI, FMA, AES-NI, SSE4.1/4.2, BMI1/2 |
| GOAMD64 hỗ trợ | tới **v3** (có AVX2) |

## 3. RAM

| | |
|---|---|
| Tổng | **16 GB** · usable ~15.3 GiB |
| Loại / tốc độ | DDR4 hoặc DDR5 _(chạy `sudo bash bin/probe-specs.sh` để xác nhận)_ |
| Hình thức | DIMM rời (HP Slim Desktop — có thể nâng cấp) |

## 4. Lưu trữ

| | |
|---|---|
| SSD | **~238 GB NVMe** (PCIe, M.2), non-rotational |
| Phân vùng | `nvme0n1p1` 512M EFI (vfat) · `nvme0n1p2` 238G ext4 (`/`) |
| Swap | `/swapfile` 2G (file, prio -2) · `/dev/zram0` 7.7G (prio 100) |
| Model SSD | _(chạy `sudo smartctl -i /dev/nvme0n1` để xác nhận)_ |

## 5. Đồ họa & màn hình

| | |
|---|---|
| GPU | **Intel UHD Graphics 730** (tích hợp i3-12100, PCI device 4692 rev 0c) |
| Màn hình | External **1920×1080@60Hz** qua DP-1 (cáp DisplayPort, màn 527×296mm) |
| Session | X11 |

## 6. Mạng

| | |
|---|---|
| Ethernet | **Realtek RTL8111/8168/8411** PCIe Gigabit |
| Wi-Fi | **Realtek RTL8822CE** 802.11ac (PCIe) |
| Bluetooth | đi kèm RTL8822CE |

## 7. Pin / nguồn

| | |
|---|---|
| Pin | **Không có** (desktop machine) |
| Nguồn | PSU desktop — luôn có điện |

> ℹ️ `health-check.sh` sẽ luôn hiển thị Pin 🔴 trên máy này — bỏ qua hoàn toàn, không phải cảnh báo thật.

## 8. Phần mềm nền (mốc, ít đổi)

| | |
|---|---|
| OS | **Ubuntu 22.04.5 LTS** (Jammy Jellyfish) |
| Kernel | **6.8.0-124-generic** x86_64 |
| Init / Desktop / Session | systemd · **GNOME** (suy đoán) · X11 |
| Quản lý nguồn | power-profiles-daemon (powerprofilesctl) |
| Go | **1.26.0** |
| GoLand | **2026.1.4** (snap `goland`) |

## 9. Đặc tính tuning

- Desktop → không có lo ngại tản nhiệt như laptop mỏng; nhiệt ngưỡng cao=80°C, crit=100°C.
- Không pin → bỏ qua hoàn toàn mục pin khi tuning.
- i3-12100 chỉ có P-cores (không có E-cores) → `thermal_throttle` ở CPU 0–3 là 4 core vật lý.
- SSD NVMe PCIe → noatime + fstrim định kỳ là hai tweak disk quan trọng nhất.
