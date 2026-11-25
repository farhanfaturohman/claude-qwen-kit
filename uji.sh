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

# alur v4: putus jaringan → ulang otomatis (resume) → periksa PERBAIKI → perbaikan sesi baru → LULUS
mkdir -p "$T/b4"
cat > "$T/b4/qwen" <<'QWENPALSU'
#!/usr/bin/env python3
import json, os, sys
U = os.environ["UJI4"]; a = sys.argv[1:]
c = os.path.join(U, "cnt"); n = int(open(c).read()) + 1 if os.path.exists(c) else 1; open(c, "w").write(str(n))
v = lambda f: a[a.index(f)+1] if f in a else "-"
j = "PERIKSA" if "--exclude-tools" in a else ("PERBAIKAN" if a[0].startswith("TAHAP: PERBAIKAN") else ("ULANG" if "sempat putus" in a[0] else "PELAKSANA"))
open(os.path.join(U, "args"), "a").write(f"{j} {'resume' if '--resume' in a else 'baru'} {'pagar' if 'ATURAN MUTLAK' in v('--append-system-prompt') else 'TANPA'}\n")
o = lambda d: print(json.dumps(d), flush=True)
if n == 1:
    o({"type": "result", "subtype": "error_during_execution", "is_error": True, "error": {"message": "[API Error: Connection error. (cause: getaddrinfo ENOTFOUND x)]"}}); sys.exit(1)
if j == "PERIKSA":
    f = os.path.join(U, "v1"); t = "VERDIK: LULUS" if os.path.exists(f) else "VERDIK: PERBAIKI\nTEMUAN: - f:1 — salah"; open(f, "a").close()
else:
    open("f", "a").write(f"{n}\n"); t = "FILE_DIUBAH: - f"
o({"type": "assistant", "message": {"content": [{"type": "text", "text": t}]}}); o({"type": "result", "subtype": "success", "num_turns": 1})
QWENPALSU
chmod +x "$T/b4/qwen"; git checkout -q f
echo brief | UJI4="$T" PATH="$T/b4:$PATH" QWEN_JEDA_ULANG=1 QWEN_PROGRESS="$T/p4" "$QE" eksekusi > "$T/o4" 2>&1
urut=$(tr '\n' ',' < "$T/args")
cek "v4: VERDIK=LULUS setelah 1 perbaikan" "grep -q 'VERDIK=LULUS PUTARAN_PERBAIKAN=1' '$T/o4'"
cek "v4: urutan pelaksana,ulang,periksa,perbaikan-baru,periksa (+pagar)" "[ \"\$urut\" = 'PELAKSANA baru pagar,ULANG resume pagar,PERIKSA baru pagar,PERBAIKAN baru pagar,PERIKSA baru pagar,' ]"

J="$HOME/.claude/bin/jaga-db"
jaga() { python3 -c 'import json,sys;print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$1" | "$J" 2>/dev/null; echo $?; }
tolak=0; for x in "php artisan migrate:fre""sh" "cd x && php artisan migrate:roll""back" "php artisan db:wi""pe" "php artisan migr""ate" \
  "php artisan db:se""ed" "mysql -e 'DROP TA""BLE x'" "vendor/bin/php""unit"; do [ "$(jaga "$x")" = 2 ] || { tolak=1; echo "    lolos: $x"; }; done
boleh=0; for x in "php artisan migrate:status" "vendor/bin/phpunit --testsuite Unit" "git status" "mysql -e 'select 1'"; do
  [ "$(jaga "$x")" = 0 ] || { boleh=1; echo "    terblokir: $x"; }; done
cek "jaga-db menolak perintah DB berbahaya & meloloskan yang aman" "[ $tolak = 0 ] && [ $boleh = 0 ]"

out=$(echo "{\"workspace\":{\"current_dir\":\"$T/repo\"}}" | "$HOME/.claude/bin/qwen-status")
cek "qwen-status jalan: $out" "[ -n \"\$out\" ]"
exit $gagal
