#!/usr/bin/env bash
# Uji pembungkus TANPA memanggil LLM: qwen palsu di repo git sementara.
# Memeriksa: penanda ■ SELESAI (normal & dihentikan), aman disunting saat jalan, status line.
set -uo pipefail
QE="$HOME/.claude/bin/qwen-exec"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/repo"
cat > "$T/bin/qwen" <<'EOF'
#!/usr/bin/env bash
sleep "${FAKE_SLEEP:-1}"
echo '{"type":"result","subtype":"success","num_turns":1,"result":"FILE_DIUBAH: -"}'
EOF
chmod +x "$T/bin/qwen"
cd "$T/repo" && git init -q && echo a > f && git add f && git -c user.email=u@u -c user.name=u commit -qm awal
gagal=0
cek() { if eval "$2"; then echo "  ✓ $1"; else echo "  ✗ $1"; gagal=1; fi; }

echo brief | PATH="$T/bin:$PATH" QWEN_VERIFIKASI=0 QWEN_PROGRESS="$T/p1" "$QE" eksekusi > "$T/o1" 2>&1
cek "selesai normal menulis ■ SELESAI EXIT=0" "grep -q '■ SELESAI EXIT=0' '$T/p1'"
cek "baris DIR & T0 untuk status line" "grep -q '^· DIR ' '$T/p1' && grep -q '^· T0 ' '$T/p1'"

echo brief > "$T/brief"
PATH="$T/bin:$PATH" FAKE_SLEEP=3 QWEN_VERIFIKASI=0 QWEN_PROGRESS="$T/p2" "$QE" eksekusi < "$T/brief" > /dev/null 2>&1 &
sleep 1.5; kill -TERM $! 2>/dev/null; wait 2>/dev/null
cek "dihentikan menulis ■ SELESAI ... DIHENTIKAN" "grep -q 'DIHENTIKAN' '$T/p2'"

cp "$QE" "$T/qe"
( echo brief | PATH="$T/bin:$PATH" FAKE_SLEEP=3 QWEN_VERIFIKASI=0 QWEN_PROGRESS="$T/p3" "$T/qe" eksekusi > "$T/o3" 2>&1; echo "rc=$?" >> "$T/o3" ) &
sleep 1; { printf '# sisipan\n%.0s' 1 2 3 4 5 6 7; cat "$QE"; } > "$T/qe"; wait
cek "disunting saat jalan tetap selesai tanpa parse error" "grep -q 'rc=0' '$T/o3' && ! grep -q 'parse error' '$T/o3'"

out=$(echo "{\"workspace\":{\"current_dir\":\"$T/repo\"}}" | "$HOME/.claude/bin/qwen-status")
cek "qwen-status jalan: $out" "[ -n \"\$out\" ]"
exit $gagal
