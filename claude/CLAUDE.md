# Alur Claude + Qwen (global, aturan tetap pengguna; dirapikan 2026-11-23)

Kuota Claude terbatas (PRIORITAS TERTINGGI). **Claude = otak singkat** (putuskan, tulis brief,
review diff). **Qwen = tangan DAN mata** (`qwen --yolo`, model `flash-next-fp8`: menjelajah, membaca
kode, mengukur, menulis, menguji, menulis laporan). Berlaku di semua proyek.

## Kapan Claude kerjakan sendiri (nol Qwen)
- Pengguna bilang "Claude kerjakan sendiri"/"tanpa qwen"/setara (kutipan atau pembahasan aturan ini
  bukan pemicu).
- Pertanyaan/penjelasan/analisis biasa; perubahan kecil ±1–3 baris di lokasi yang jelas.
- Mengubah pembungkus Qwen sendiri (`~/.claude/bin/qwen-*`) — selalu tulis ke file sementara, `zsh -n`,
  lalu `mv` (jangan sunting di tempat: sesi yang sedang jalan bisa mati "parse error", 2026-11-24).
  Sumber bersama mesin lain/server: repo `~/Desktop/claude-qwen-kit` — setelah mengubah pembungkus atau
  file ini, jalankan `./ambil.sh` di sana (commit/push hanya bila pengguna minta).
- Qwen gagal/auth/kuota → periksa perubahan parsial, laporkan, **tanyakan** pengguna sebelum
  mengambil alih penuh.

## Selain itu → Qwen
- **Eksplorasi/riset/audit** (>3 file, cari di kode, query/harness) → `kritik` (baca saja) atau
  `eksekusi` (bila menulis dokumen/skrip); temuan ditulis ke berkas. Claude membaca laporan/ringkasan,
  bukan kode mentah. Batas baca Claude: ±3 file kecil atau `sed -n`/`grep` tertarget, hanya untuk
  memutuskan/menulis brief; jangan ulang query yang sudah Qwen laporkan.
- **Implementasi**: sederhana → brief → `eksekusi`. Menengah → brief berisi tujuan, area, kriteria
  selesai (Qwen boleh berhenti di KENDALA). Rumit/sensitif (DB, nilai/gaji/SLA, cetakan, autentikasi,
  lintas modul) → rencana Claude → `kritik` → arahan akhir → `eksekusi`.
- Satu penulis per area pada satu waktu.

## Brief
Ringkas: tujuan · file/area boleh diubah (path:baris bila sudah tahu) · yang tak boleh disentuh ·
kriteria selesai · perintah tes. Rujuk berkas yang ada (handoff/§nomor) alih-alih menyalin. Boleh
beberapa langkah berurutan dalam satu brief. Lokasi belum diketahui → biarkan Qwen mencari.
**Pecah kecil (Qwen lambat bila jelajah luas / tugas besar):** satu brief = satu area, ±1–5 file, target
selesai ≤15 menit. Tugas besar → urutan brief kecil (tiap brief diverifikasi sendiri; brief berikut merujuk
hasil sebelumnya), bukan satu brief raksasa. Lokasi belum jelas → dulu `kritik` ringan "petakan file:baris
sasaran, tulis ke <berkas>" (QWEN_MAX_TURNS=25), lalu brief eksekusi merujuk peta itu → Qwen tak perlu jelajah.
**SASARAN:** sebut path(:baris) yang Claude sudah tahu — pembungkus menyuruh Qwen langsung ke sana.
**TITIK CEK:** (wajib untuk eksekusi; bagian berjudul `TITIK CEK:` diakhiri baris kosong) 2–6 butir terukur yang
Claude petakan dari tujuan, satu baris bernomor per butir (bagian berhenti di baris kosong/`Kata:` berikutnya) —
`$ grep -q 'X' path`, `$ php vendor/bin/phpunit --testsuite Unit --filter Y`, atau kalimat untuk pemeriksa
("rute Z memuat teks W", "tak ada perubahan di luar A/B"). `$` hanya perintah BACA (>, rm, sed -i ditolak). Pelaksana melapor `CEK n: ✓/✗ — bukti`; pemeriksa wajib
menilai tiap butir; satu ✗ → otomatis PERBAIKI walau tertulis LULUS. Output memuat `TITIK_CEK: a ✓ · b ✗`.
Utamakan butir **`$ perintah`** (mis. `1. $ grep -q 'x' path`, `$ php -l path`, `$ php vendor/bin/phpunit --testsuite Unit
--filter Y`): dijalankan MESIN pembungkus (lewat jaga-db), objektif, ✗ → PERBAIKI. Semua butir `$` + lolos +
patch ≤20 baris + `QWEN_AREA` diisi & tak ada file di luarnya → `VERDIK=LULUS_MESIN` tanpa pemeriksa Qwen (hemat
±24 giliran). Butir non-`$` dinilai pemeriksa. `⊘`/`!! cek mengubah` = butir brief tak sah → betulkan brief, bukan Qwen.
v5 otomatis: peta `git grep` kata kunci brief ditempel ke prompt (sebut nama kelas/view/rute/`kode` di brief),
alat Qwen dipangkas (−23% token/giliran), `METRIK:` per tahap di output (+ `qwen-logs/metrik.csv`).
`⚠ TUGAS BESAR` di output (tahap >40 giliran; biang lambat = jumlah panggilan × ±10–25 dtk) → brief berikutnya
WAJIB dipecah per area / paralel worktree.
**Paralel:** brief kecil yang areanya terpisah → jalankan serentak dengan `QWEN_WORKTREE=1` (worktree sendiri,
vendor di-clone, hasil diterapkan ke folder asli di akhir; `WORKTREE: ⚠ KONFLIK` → worktree disimpan, revisi
`QWEN_WORKTREE=<path> qwen-exec eksekusi <SESSION>`). File untracked folder asli tak ikut ke worktree.
Pagar YOLO (larangan commit/push/destruktif/tulis DB, DB lokal = PROD, tes hanya Unit), baca
AGENTS.md/QWEN.md, dan format laporan SUDAH ditambah pembungkus — jangan ditulis ulang.

## Memanggil (dari root repo, selalu `run_in_background: true`)
```
rm -f ~/.claude/qwen-logs/<slug>.progress; QWEN_PROGRESS=~/.claude/qwen-logs/<slug>.progress \
QWEN_AREA='<regex path boleh ditulis>' ~/.claude/bin/qwen-exec <eksekusi|kritik> [SESSION] <<'BRIEF'
...
BRIEF
```
- Env: `QWEN_AREA` (file berubah di luar regex ditandai ⚠ LUAR) · `QWEN_RINGAN=1` (cek cepat, tanpa
  baca AGENTS/QWEN.md) · tugas besar `QWEN_MAX_TURNS=150 QWEN_MAX_WALL=45m QWEN_MAX_TOOLS=500`
  (bawaan 60/20m/250; jatah per SESSION kumulatif — habis cepat → sesi baru dengan brief "lanjutan")
  · `QWEN_EKOR` (byte tiap bagian laporan yang dicetak, bawaan 1500).
- **Hemat konteks Claude**: indeks memori (`MEMORY.md`) tiap proyek ≤ ±9 KB (kait tetap bermakna: ≤60 char, istilah kunci), satu baris per
  entri dikelompokkan per tema; rincian di file memorinya. Satu tugas = satu chat (sarankan `/clear`
  saat ganti topik bila percakapan sudah panjang).
- **Eksekusi otomatis berlapis** (v3): pelaksana → **Qwen pemeriksa independen** (sesi baru, read-only,
  membaca patch sesi ini saja, menjalankan ulang tes) → bila PERBAIKI, pelaksana memperbaiki otomatis
  (`QWEN_PUTARAN`, bawaan 1; sensitif → 2) → diperiksa ulang. Matikan: `QWEN_VERIFIKASI=0`.
  v4: pagar di system prompt (tahan ringkasan konteks); perbaikan di **sesi baru** ramping (brief+patch+
  temuan; `QWEN_PERBAIKAN=lanjut` = cara lama); putus jaringan → ulang otomatis 1× (`⚠ JARINGAN` di progres).
  Bila ada perbaikan, `SESSION=` di output = sesi perbaikan terakhir (pakai itu untuk revisi).
- Output: `SESSION= EXIT= VERDIK=` · **FILE_BERUBAH** (diukur pembungkus, termasuk file yang sudah kotor;
  patch sesi di `<log>.patch`) · ekor VERIFIKASI · ekor LAPORAN PELAKSANA. Log penuh di
  `~/.claude/qwen-logs/`; baca hanya bila perlu.
- Di luar repo git (mis. ~/Desktop): FILE_BERUBAH tak terukur → untuk tugas yang menulis WAJIB pasang
  Monitor qwen-awasi dengan regex area sempit, dan jalankan dari folder sesempit mungkin (bukan `~`).
- **Progres untuk pengguna** tampil gratis di status line (`~/.claude/bin/qwen-status`, refresh 5 dtk:
  tahap · durasi · jumlah tool · aksi terakhir) — Claude tak perlu melaporkan progres.
- **Tanda selesai = notifikasi tugas Bash latar** (selalu datang, termasuk gagal/dihentikan; progres
  selalu diakhiri `■ SELESAI`). Monitor dibatasi 30 menit, sedangkan v3 (pelaksana+pemeriksa+perbaikan)
  bisa 60–80 menit: Monitor kedaluwarsa itu wajar dan **tidak perlu dipasang ulang** hanya untuk tahu
  selesai. Pasang ulang hanya bila ingin terus menangkap ⚠.
- Pemantauan (opsional, tugas yang menulis): Monitor `timeout_ms: 1800000`, command
  `~/.claude/bin/qwen-awasi <progres> '<regex area>'` — hanya bersuara pada ▶ MULAI, ⚠ BAHAYA, ⚠ LUAR,
  ⚠ PUTAR, ■ SELESAI (berhenti sendiri). `qwen-ikuti`
  (semua event) hanya bila pengguna minta lihat proses rinci. Tanggapan event: ≤1 kalimat/tanpa teks.
- **Sabar**: tunggu notifikasi; DILARANG polling output, sleep, tail -f, ps, membaca log sebelum
  selesai, mencicil file sasaran, atau Qwen kedua di area sama. Lama ≠ macet. Boleh akhiri giliran
  sambil menyebut SESSION.
- **Campur tangan hanya bila** di luar area brief, perintah terlarang/tulis DB, salah tujuan, atau
  berputar tanpa kemajuan: `TaskStop` → laporkan → resume `qwen-exec <tahap> <SESSION>` dengan koreksi
  singkat. Salah kecil yang Qwen perbaiki sendiri bukan alasan.
- EXIT=53 (turn habis) / 55 (waktu/tool habis) → periksa parsial, **resume SESSION yang sama**.
- Revisi: `qwen-exec eksekusi <SESSION>` + koreksi singkat (jangan kirim ulang brief penuh).
- Kritik: alat tulis dibuang; plan mode tak dipakai (memblokir baca di headless). Jangan pakai
  `--json-schema` (model tak memanggil structured_output).

## Sebelum & sesudah
- Sebelum: catat `git status --short`; bila file sasaran sudah kotor, `git diff -- <file>`
  (pekerjaan pengguna jangan tertimpa/ikut di-commit).
- **Review Claude = gerbang akhir saja**, berdasarkan VERDIK:
  - `LULUS`/`LULUS_MESIN` + tak ada ⚠ LUAR → langsung lapor ke pengguna, **tanpa membaca diff** (kecuali tugas sensitif:
    lihat cepat `<log>.patch` file kunci saja).
  - `PERLU_CLAUDE` / `PERBAIKI` (putaran habis) / `TAK_TERBACA` / ⚠ LUAR / EXIT≠0 → baca TEMUAN, lalu patch
    file yang disebut saja; putuskan atau tanya pengguna; revisi lewat resume SESSION.
  - Jangan ulang tes yang sudah dijalankan ulang pemeriksa. Verifikasi besar → tahap Qwen terpisah.
- Jawaban ke pengguna ringkas: hasil, angka kunci, keputusan yang dibutuhkan; tanpa narasi proses.
  Sebut pelaku dengan jelas: "Qwen dilanjutkan (sesi X)" / "Claude mengerjakan sendiri" — jangan "saya akan
  melanjutkan" yang ambigu.
- **QWEN.md tiap proyek ≤ ±5 KB** (Qwen Code memuatnya otomatis tiap giliran, ±20rb token bila
  gemuk). Aturan modul ditaruh di `docs/qwen/<topik>.md` + tabel pemicu di QWEN.md (pola repo pegawai,
  commit 2e8196fb7). Bila menemukan QWEN.md > 5 KB di proyek mana pun → tawarkan pecah via Qwen
  dengan verifikasi baris 100%.
- **Blokir DB berbahaya** (hook `~/.claude/bin/jaga-db`, Claude Bash + Qwen run_shell_command, berlaku juga
  di yolo): migrate tanpa --pretend + varian fresh/refresh/reset/rollback, wipe, seed, DROP/TRUNCATE/DELETE
  tanpa WHERE, Schema drop, tes non-Unit. Bila DITOLAK: jangan cari jalan lain; minta pengguna jalankan manual.
  Positif palsu (teks perintah memuat pola) → pakai alat Edit/Grep, bukan Bash.
- Commit hanya bila pengguna minta; Qwen tidak pernah commit. Jangan klaim angka penghematan token
  yang tidak diukur.
