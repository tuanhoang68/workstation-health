#!/usr/bin/env bash
# tweaks/tier3a-cleanup-user.sh — Bước 3a (phần KHÔNG cần sudo): dọn cache/rác user.
# BẢO VỆ: ~/.cache/go-build (build Go) + ~/.cache/JetBrains/GoLand2026.1 (index đang dùng).
# Chạy: bash tweaks/tier3a-cleanup-user.sh
set -uo pipefail
H="$HOME"
echo "== df TRƯỚC =="; df -h / | sed 's/^/  /'
reclaim() { echo "  • $1: $(du -sh "$2" 2>/dev/null | cut -f1 || echo 0)"; }

echo "== Sẽ dọn (đã trừ phần bảo vệ) =="
reclaim "Thùng rác"        "$H/.local/share/Trash/files"
reclaim "Chrome cache"     "$H/.cache/google-chrome"
reclaim "JetBrains 2025.2" "$H/.cache/JetBrains/GoLand2025.2"
reclaim "JetBrains 2025.3" "$H/.cache/JetBrains/GoLand2025.3"
reclaim ".npm"             "$H/.npm"
reclaim "thumbnails"       "$H/.cache/thumbnails"
reclaim "mesa shader"      "$H/.cache/mesa_shader_cache"

echo "== Thực hiện xóa =="
rm -rf "$H/.local/share/Trash/files/"* "$H/.local/share/Trash/info/"* 2>/dev/null; echo "  ✓ thùng rác"
rm -rf "$H/.cache/google-chrome/"*       2>/dev/null; echo "  ✓ chrome cache"
rm -rf "$H/.cache/JetBrains/GoLand2025.2" "$H/.cache/JetBrains/GoLand2025.3" 2>/dev/null; echo "  ✓ jetbrains cũ (giữ 2026.1)"
if command -v npm >/dev/null; then npm cache clean --force >/dev/null 2>&1; else rm -rf "$H/.npm/_cacache" 2>/dev/null; fi; echo "  ✓ npm cache"
rm -rf "$H/.cache/thumbnails/"*          2>/dev/null; echo "  ✓ thumbnails"
rm -rf "$H/.cache/mesa_shader_cache/"*   2>/dev/null; echo "  ✓ mesa shader cache"

echo "== BẢO VỆ (không đụng): go-build $(du -sh $H/.cache/go-build 2>/dev/null|cut -f1) · GoLand2026.1 $(du -sh $H/.cache/JetBrains/GoLand2026.1 2>/dev/null|cut -f1) =="
echo "== df SAU =="; df -h / | sed 's/^/  /'
echo "✅ Xong 3a (user). Tiếp: chạy phần sudo."
