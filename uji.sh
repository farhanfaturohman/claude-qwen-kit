#!/usr/bin/env bash
# Uji pembungkus TANPA memanggil LLM: qwen palsu di repo git sementara.
# Memeriksa: penanda ■ SELESAI (normal & dihentikan), aman disunting saat jalan, status line.
set -uo pipefail
export QWEN_UJI=1   # metrik qwen palsu tak dicatat ke metrik.csv
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
j = "PERIKSA" if a[0].startswith("TAHAP: VERIFIKASI") else ("PERBAIKAN" if a[0].startswith("TAHAP: PERBAIKAN") else ("ULANG" if "sempat putus" in a[0] else "PELAKSANA"))
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

# titik cek: pemeriksa menulis LULUS tapi ada CEK ✗ → dipaksa PERBAIKI → perbaikan → LULUS semua ✓
mkdir -p "$T/b5"; rm -f "$T/cnt5" "$T/v5"
cat > "$T/b5/qwen" <<'QWENCEK'
#!/usr/bin/env python3
import json, os, sys
U = os.environ["UJI5"]; a = sys.argv[1:]; p = a[0]
o = lambda d: print(json.dumps(d), flush=True)
if a[0].startswith("TAHAP: VERIFIKASI"):
    open(os.path.join(U, "pv5"), "w").write(p)
    f = os.path.join(U, "v5"); kedua = os.path.exists(f); open(f, "a").close()
    t = "VERDIK: LULUS\nCEK 1: ✓ — ok\nCEK 2: " + ("✓ — ok" if kedua else "✗ — belum")
else:
    if not p.startswith("TAHAP: PERBAIKAN"): open(os.path.join(U, "pe5"), "w").write(p)
    open("f", "a").write("x\n"); t = "FILE_DIUBAH: - f\nCEK 1: ✓\nCEK 2: ✓"
o({"type": "assistant", "message": {"content": [{"type": "text", "text": t}]}}); o({"type": "result", "subtype": "success", "num_turns": 1})
QWENCEK
chmod +x "$T/b5/qwen"; git checkout -q f
printf 'ubah f\n\nTITIK CEK:\n1. f bertambah baris\n2. grep -c x f >= 1\n\nlain: -\n' | UJI5="$T" PATH="$T/b5:$PATH" QWEN_PROGRESS="$T/p5" "$QE" eksekusi > "$T/o5" 2>&1
cek "titik cek: ✗ memaksa perbaikan lalu LULUS 2/2" "grep -q 'VERDIK=LULUS PUTARAN_PERBAIKAN=1' '$T/o5' && grep -q 'TITIK_CEK (pemeriksa terakhir): 2 ✓ · 0 ✗ dari 2 titik' '$T/o5'"
cek "titik cek sampai ke prompt pelaksana & pemeriksa" "grep -q 'TITIK_CEK: satu baris' '$T/pe5' && grep -q 'grep -c x f' '$T/pv5'"

# v5: cek mesin, jalur sepele, alat ramping, peta otomatis, metrik, worktree
mkdir -p "$T/b6"
cat > "$T/b6/qwen" <<'QWEN6'
#!/usr/bin/env python3
import json, os, sys, time
U = os.environ["UJI6"]; a = sys.argv[1:]; p = a[0]
j = "PERIKSA" if p.startswith("TAHAP: VERIFIKASI") else ("PERBAIKAN" if p.startswith("TAHAP: PERBAIKAN") else "PELAKSANA")
open(os.path.join(U, "log6"), "a").write(json.dumps({"j": j, "a": a[1:], "p": p, "cwd": os.getcwd()}) + "\n")
if j == "PELAKSANA": open("f", "a").write("baris\n")
if j == "PELAKSANA" and os.environ.get("ARTEFAK6"): os.makedirs("__pycache__", exist_ok=True); open("__pycache__/m.cpython-314.pyc", "wb").write(b"\x00\x01\x02biner")
if os.environ.get("TIDUR6"): time.sleep(float(os.environ["TIDUR6"]))
if os.environ.get("KONFLIK6"): open(os.environ["KONFLIK6"], "w").write("lain\n")   # suntingan serentak di folder asli
if j == "PERBAIKAN": open("f", "a").write("fixed\n")
t = "VERDIK: LULUS\nCEK 2: ✓ — ok" if j == "PERIKSA" else "FILE_DIUBAH: - f"
o = lambda d: print(json.dumps(d), flush=True)
o({"type": "assistant", "message": {"content": [{"type": "tool_use", "name": "read_file", "input": {}}], "usage": {"input_tokens": 1000}}})
o({"type": "assistant", "message": {"content": [{"type": "text", "text": t}]}})
o({"type": "result", "subtype": "success", "num_turns": 1, "duration_ms": 60000, "usage": {"input_tokens": 1000}})
QWEN6
chmod +x "$T/b6/qwen"
q6() { rm -f "$T/log6"; git checkout -q f; UJI6="$T" PATH="$T/b6:$PATH" QWEN_PROGRESS="$T/p6" "$QE" eksekusi > "$T/$1" 2>&1; }
j6() { python3 -c 'import json,sys; [print(d["j"], " ".join(d["a"]).replace(chr(10), " ⏎ "), "|", d["p"].replace(chr(10), " ⏎ "), "|", d["cwd"]) for d in map(json.loads, open(sys.argv[1]))]' "$T/log6"; }
echo 'class LayananUji {}' > LayananUji.php; git add LayananUji.php; git -c user.email=u@u -c user.name=u commit -qm layanan
printf 'ubah f, lihat LayananUji\n\nTITIK CEK:\n1. $ grep -q baris f\n2. $ test -f f\n' | QWEN_AREA='^f$' q6 o6
cek "v5 sepele: semua cek mesin ✓ → LULUS_MESIN tanpa pemeriksa Qwen" "grep -q 'VERDIK=LULUS_MESIN' '$T/o6' && ! j6 | grep -q '^PERIKSA' && grep -q 'CEK_MESIN: 2 ✓ · 0 ✗' '$T/o6'"
cek "v5 alat ramping: pelaksana tanpa cron/agent, tetap boleh edit" "j6 | grep '^PELAKSANA' | grep -q 'exclude-tools.*cron_create' && ! j6 | grep '^PELAKSANA' | grep -qE 'exclude-tools[^|]* edit '"
cek "v5 peta otomatis: LayananUji.php masuk prompt" "j6 | grep '^PELAKSANA' | grep -q 'PETA OTOMATIS.*LayananUji.php'"
cek "v5 metrik per tahap di keluaran & metrik.csv" "grep -q '^METRIK:' '$T/o6' && grep -q 'pelaksana: 1.0m · 1 giliran · 1 alat' '$T/o6'"
printf 'ubah f\n\nTITIK CEK:\n1. $ grep -q fixed f\n2. isi f wajar\n' | q6 o7
cek "v5 cek mesin ✗ memaksa perbaikan (walau pemeriksa LULUS) → LULUS" "grep -q 'VERDIK=LULUS PUTARAN_PERBAIKAN=1' '$T/o7' && j6 | grep '^PERBAIKAN' | grep -q 'CEK MESIN GAGAL'"
printf 'ubah f\n' | QWEN_WORKTREE=1 QWEN_VERIFIKASI=0 q6 o8
wt=$(sed -n 's/^· WORKTREE \([^ ]*\) .*/\1/p' "$T/p6")
cek "v5 worktree: Qwen di worktree, hasil diterapkan ke folder asli, worktree dibersihkan" "grep -q 'WORKTREE: 1 file diterapkan' '$T/o8' && grep -q baris f && [ -n '$wt' ] && [ ! -d '$wt' ] && j6 | grep -q '| $wt'"
printf 'ubah f\n' | KONFLIK6="$PWD/f" QWEN_WORKTREE=1 QWEN_VERIFIKASI=0 q6 o9
wt=$(sed -n 's/^· WORKTREE \([^ ]*\) .*/\1/p' "$T/p6")
cek "v5 worktree konflik: tak menimpa folder asli, worktree disimpan" "grep -q 'KONFLIK' '$T/o9' && grep -qx lain f && [ -d '$wt' ] && grep -q 'worktree disimpan' '$T/o9'"
printf 'ulang\n' | QWEN_WORKTREE="$wt" QWEN_VERIFIKASI=0 q6 o10
cek "v5 worktree dipakai ulang (revisi) → diterapkan & dibersihkan" "grep -q 'WORKTREE: 1 file diterapkan' '$T/o10' && [ \$(grep -c baris f) = 2 ] && [ ! -d '$wt' ]"
printf 'ubah f\n\nTITIK CEK:\n1. $ grep -q baris f\n2. $ test -f f\n' | q6 o11
cek "review: tanpa QWEN_AREA tak ada jalan pintas LULUS_MESIN (pemeriksa Qwen tetap jalan)" "grep -q 'VERDIK=LULUS ' '$T/o11' && j6 | grep -q '^PERIKSA'"
printf 'ubah f\n\nTITIK CEK:\n1. $ grep -q baris f\nCatatan: hanya file f\n' | QWEN_AREA='^f$' q6 o12
cek "review: ekstraksi TITIK CEK berhenti di header 'Catatan:'" "grep -q 'VERDIK=LULUS_MESIN' '$T/o12'"
printf 'ubah f\n\nTITIK CEK:\n1. $ python3 -c "open(\x27sampah.txt\x27,\x27w\x27)"\n2. $ grep -c baris f >= 1\n' | QWEN_AREA='^f$' q6 o13
cek "review: cek mesin tolak redirect & kode penulis (⊘), tanpa sisa berkas" "grep -q 'CEK 1: ⊘' '$T/o13' && grep -q 'CEK 2: ⊘' '$T/o13' && [ ! -e sampah.txt ] && [ ! -e '=' ] && [ ! -e 1 ]"
cek "review2: butir ⊘ tidak memaksa PERBAIKI (pelaksana tak bisa membetulkan brief)" "grep -q 'PUTARAN_PERBAIKAN=0' '$T/o13' && grep -q 'betulkan brief' '$T/o13'"
printf 'ubah f\n\nTITIK CEK:\n1. $ sh -c "echo rusak > f; true"\n2. $ grep -c touch f; true\n' | QWEN_AREA='^f$' q6 o17
cek "review2: penulisan tersembunyi oleh cek dipulihkan; grep berargumen 'touch' tidak ditolak" "grep -q 'DIPULIHKAN' '$T/o17' && grep -qx baris f && grep -q 'CEK 2: ✓' '$T/o17'"
printf 'ubah f\n\nTITIK CEK:\n1. $ grep -q baris f\n' | ARTEFAK6=1 QWEN_AREA='^f$' q6 o16
cek "artefak __pycache__ tak dihitung LUAR → LULUS_MESIN tetap berlaku" "grep -q 'VERDIK=LULUS_MESIN' '$T/o16' && grep -q '· artefak __pycache__' '$T/o16'"
rm -rf __pycache__
QWEN_WORKTREE=/tidak/ada q6 o14 <<< 'x'
cek "review: gagal awal worktree tetap mencetak SESSION= & ■ SELESAI" "grep -q '^SESSION=.*EXIT=2 VERDIK=GAGAL_PEMBUNGKUS' '$T/o14' && grep -q '■ SELESAI EXIT=2' '$T/p6'"
( printf 'ubah f\n' | UJI6="$T" TIDUR6=4 QWEN_WORKTREE=1 QWEN_VERIFIKASI=0 PATH="$T/b6:$PATH" QWEN_PROGRESS="$T/p15" "$QE" eksekusi > "$T/o15" 2>&1 ) &
sleep 2; pkill -TERM -f "qwen-exec eksekusi" -P $! 2>/dev/null || kill -TERM $(pgrep -P $! -f qwen-exec) 2>/dev/null; wait
wt=$(sed -n 's/^· WORKTREE \([^ ]*\) .*/\1/p' "$T/p15")
cek "review: dihentikan di mode worktree → lokasi worktree dicetak, tak hilang" "grep -q 'dihentikan — hasil BELUM diterapkan' '$T/o15' && [ -d '$wt' ]"
[ -n "$wt" ] && { git worktree remove --force "$wt" 2>/dev/null; git update-ref -d "refs/qwen-wt/$(basename "$wt")" 2>/dev/null; rm -f "$wt.base" "$wt.asli"; }
git checkout -q f

# review3: jaring pengaman cek mesin tak bergantung git stash (index.lock tak boleh menghapus kerja pengguna)
R=$(mktemp -d); ( cd "$R" && git init -q && echo AWAL > f.txt && echo AWAL > 'é.txt' && git add . && git -c user.email=u@u -c user.name=u commit -qm a \
  && echo 'KERJA PENGGUNA' > f.txt && echo 'KERJA PENGGUNA' > 'é.txt' && touch .git/index.lock \
  && printf '1. $ sh -c "echo ZZ > f.txt; echo ZZ > é.txt; true"\n2. $ grep -rn "file_put_contents" . || true\n' > c \
  && python3 "$HOME/.claude/bin/qwen-cekmesin" c > o; echo "rc=$?" >> o )
cek "review3: index.lock + path non-ASCII → kerja pengguna dipulihkan utuh; grep nama fungsi tak ditolak" "grep -qx 'KERJA PENGGUNA' '$R/f.txt' && grep -qx 'KERJA PENGGUNA' '$R/é.txt' && grep -q 'CEK 2: ✓' '$R/o' && grep -q 'rc=4' '$R/o'"
rm -rf "$R"

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
