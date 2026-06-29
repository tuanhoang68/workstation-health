# Thiết kế đợt tối ưu: <CHỦ-ĐỀ> (<NGÀY>)

- **Sinh từ health:** `../report.md` · **Lý do:** <cờ đỏ/nhu cầu>
- **Risk tolerance:** <Balanced/Safe/Aggressive>
- **Phạm vi đau cần xử lý:** <...>

## 1. Baseline (số thật trước tối ưu)
| Hạng mục | Giá trị baseline |
|---|---|
| ... | ... |

## 2. Kế hoạch theo tier (theo impact)
### Tier 1 — <tên>
1. <tweak> — cách làm — rollback.

## 3. Bộ thông số đo (before/after)
- Công cụ: `bin/bench.sh ...`
- Kịch bản tải chuẩn (lặp lại được): <...>
- Ma trận thông số từng tier: <...>

## 4. Tiêu chí thành công
- <điều kiện đạt>

## 5. Thứ tự thực thi (từng bước, mỗi bước 1 report trong steps/)
1. Đo baseline → 2. Áp tweak → 3. Đo after → 4. Ghi steps/step-N.md → 5. DỪNG chờ go/rollback.
> Lệnh sudo: soạn script trong `../../../tweaks/` cho user tự chạy (máy không passwordless sudo).
