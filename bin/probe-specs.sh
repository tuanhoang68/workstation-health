#!/usr/bin/env bash
# probe-specs.sh — lấy thông số phần cứng cần root (RAM module, SSD SMART, BIOS chi tiết).
# Chạy: sudo bash probe-specs.sh   → copy output cho AI điền vào docs/machine-specs.md
set -uo pipefail
if [ "$(id -u)" -ne 0 ]; then echo "❌ Cần sudo: sudo bash $0"; exit 1; fi

echo "########## RAM MODULES (dmidecode) ##########"
dmidecode -t memory 2>/dev/null | grep -E "Size|Type:|Type Detail|Speed|Configured|Manufacturer|Part Number|Locator|Rank|Form Factor" | grep -viE "Error|Unknown" | sed 's/^[[:space:]]*//'

echo; echo "########## SYSTEM / BOARD / BIOS ##########"
dmidecode -t system -t baseboard -t bios 2>/dev/null | grep -E "Manufacturer|Product Name|Version|Serial|UUID|Release Date|BIOS Revision|Family" | sed 's/^[[:space:]]*//'

echo; echo "########## SSD SMART (/dev/sda) ##########"
smartctl -i /dev/sda 2>/dev/null | grep -iE "Model|Serial|Firmware|Capacity|Form Factor|SATA|Rotation" | sed 's/^[[:space:]]*//'
echo "--- health ---"
smartctl -H -A /dev/sda 2>/dev/null | grep -iE "result|Power_On_Hours|Power_Cycle|Wear|Reallocated|Total_LBAs_Written|Pending|CRC|Temperature" | sed 's/^[[:space:]]*//'

echo; echo "########## BATTERY (design) ##########"
dmidecode -t 22 2>/dev/null | grep -E "Name|Manufacturer|Design Capacity|Design Voltage|Chemistry" | sed 's/^[[:space:]]*//'
echo "✅ Copy toàn bộ output trên cho AI để điền machine-specs.md"
