#!/usr/bin/env bash
# Kebalikan install.sh — dipakai di mesin UTAMA (Mac) setelah pembungkus/aturan diubah:
# salin versi terpasang ke repo kit, lalu tinjau & commit/push.
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
for f in "$KIT"/bin/*; do cp -p "$HOME/.claude/bin/$(basename "$f")" "$f"; done
cp "$HOME/.claude/CLAUDE.md" "$KIT/claude/CLAUDE.md"
cp "$HOME/.qwen/QWEN.md" "$KIT/qwen/QWEN.md"
cd "$KIT" && git status --short && echo "Tinjau 'git diff', lalu commit & push. Di server: git pull && ./install.sh"
