# Lập lịch tác vụ trên Ubuntu: systemd timer vs cron

> Kiến thức tham khảo (xuyên suốt, không gắn 1 đợt nào). Bối cảnh: dùng để hiểu cách
> `health-check.timer` trong workspace này được dựng, và cách setup lịch chạy nói chung.

## TL;DR
- **systemd timer** = `.service` (chạy *gì*) + `.timer` (chạy *khi nào*). Mạnh hơn: chạy bù khi
  máy tắt, log tập trung, tránh dồn lúc boot. → **Chọn cho laptop** (hay tắt/ngủ).
- **cron** = 1 dòng trong crontab. Đơn giản, nhưng **bỏ lần chạy nếu máy tắt đúng giờ** và môi
  trường tối giản dễ gây lỗi. → Hợp máy 24/7 hoặc task nhanh.

---

## 1. systemd timer (cách workspace này đang dùng)

Cặp file đặt ở `~/.config/systemd/user/` (cấp user → KHÔNG cần sudo):

**`health-check.service`** — việc cần làm:
```ini
[Unit]
Description=Weekly workstation health check

[Service]
Type=oneshot
ExecStart=/bin/bash %h/GolandProjects/workstation-health/bin/health-check.sh weekly
```

**`health-check.timer`** — lịch:
```ini
[Unit]
Description=Chạy health-check hằng tuần

[Timer]
OnCalendar=Mon 10:00      # mỗi Thứ 2 10:00
Persistent=true           # ⭐ chạy BÙ nếu lúc đó máy tắt
RandomizedDelaySec=30m    # lệch ngẫu nhiên ≤30p, tránh dồn lúc boot

[Install]
WantedBy=timers.target
```

Kích hoạt & quản lý:
```bash
systemctl --user daemon-reload                    # nạp file mới
systemctl --user enable --now health-check.timer  # bật + khởi động
systemctl --user list-timers                      # xem lịch kế tiếp
systemctl --user start  health-check.service      # chạy thử ngay 1 lần
systemctl --user disable health-check.timer       # tắt tự động
journalctl --user -u health-check.service         # xem log các lần chạy
```

**Quy ước:** `.timer` và `.service` **cùng tên** → timer tự gọi service tương ứng. Khác tên thì
thêm `Unit=ten-khac.service` trong `[Timer]`.

**`OnCalendar` cú pháp:** `DOW Y-M-D H:M:S`. Ví dụ: `daily`, `weekly`, `*-*-01 03:00` (mùng 1 hàng
tháng 3h), `Mon,Thu 09:00`, `*:0/15` (mỗi 15 phút). Kiểm tra: `systemd-analyze calendar "Mon 10:00"`.

**Chạy cả khi CHƯA đăng nhập:** user timer chỉ chạy khi user manager sống. Muốn chạy nền kể cả
chưa login: `loginctl enable-linger $USER` (tùy chọn; laptop dùng hằng ngày thường không cần).

**Timer cấp hệ thống** (cần sudo): đặt ở `/etc/systemd/system/`, dùng `systemctl` (không `--user`).

---

## 2. cron

**Crontab user** (không sudo):
```bash
crontab -e      # sửa lịch
crontab -l      # liệt kê
crontab -r      # xoá sạch (cẩn thận)
```

**Cú pháp 5 trường:** `phút giờ ngày-tháng tháng thứ  lệnh`
```
0 10 * * 1  /bin/bash /path/health-check.sh weekly >> ~/hc.log 2>&1
│  │ │ │ │
│  │ │ │ └─ thứ (0/7=CN,1=T2…6=T7)
│  │ │ └─── tháng (1–12)
│  │ └───── ngày trong tháng (1–31)
│  └─────── giờ (0–23)
└────────── phút (0–59)
```
`*`=mọi giá trị · `*/5`=mỗi 5 · `1-5`=khoảng · `1,3,5`=danh sách.
Chuỗi tắt: `@reboot @hourly @daily @weekly @monthly`.

**Cron hệ thống** (sudo): `/etc/crontab`, `/etc/cron.d/*` — có **thêm trường user**:
`0 10 * * 1 root /path/script`. Và `/etc/cron.{daily,weekly,monthly}/` — bỏ script vào là tự chạy
(qua `anacron`/`run-parts`).

**3 BẪY hay gặp:**
1. **PATH tối giản** → luôn dùng đường dẫn tuyệt đối (`/bin/bash`, full path). Lỗi #1.
2. **Mất output** → cron không in ra terminal; tự `>> file 2>&1`.
3. **Không chạy bù** → máy tắt đúng giờ là bỏ luôn lần đó. (`anacron` chạy bù nhưng chỉ theo
   daily/weekly/monthly, không theo giờ cụ thể.)

Log cron: `journalctl -u cron` hoặc `grep CRON /var/log/syslog`.

---

## 3. So sánh & chọn

| Tiêu chí | systemd timer | cron |
|---|---|---|
| Máy tắt lúc hẹn → chạy bù | ✅ `Persistent=true` | ❌ (anacron: một phần) |
| Log tập trung | ✅ `journalctl` | ⚠️ tự redirect |
| Tránh dồn lúc boot | ✅ `RandomizedDelaySec` | ❌ |
| Điều kiện/phụ thuộc | ✅ `After=`, `ConditionACPower=`… | ❌ |
| Gõ nhanh, đơn giản | ✋ dài hơn (2 file) | ✅ 1 dòng |

- **Laptop / desktop** (hay tắt/ngủ) → **systemd timer** (vì `Persistent`).
- **Server 24/7 / task nhanh** → cron cũng ổn.

Workspace này chọn **timer** vì laptop hay tắt → cần chạy bù để không bỏ tuần nào.
