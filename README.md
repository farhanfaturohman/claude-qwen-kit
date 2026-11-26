# Kit Claude + Qwen

Alur kerja hemat kuota: **Claude = otak** (memutuskan, menulis brief, gerbang akhir), **Qwen = tangan
& mata** (menjelajah, menulis, menguji, memeriksa silang). Kit ini memasang alur yang sama di mesin
mana pun: laptop, server, atau VM.

| Isi | Dipasang ke |
|---|---|
| `bin/qwen-exec` — pembungkus: pelaksana → pemeriksa independen → perbaikan otomatis | `~/.claude/bin/` |
| `bin/qwen-saring.py`, `qwen-awasi`, `qwen-ikuti` — saringan progres & pemantau | `~/.claude/bin/` |
| `bin/qwen-status` — status line progres Qwen + judul tab ⏳ selama Qwen jalan (lokal, **nol token Claude**) | `~/.claude/bin/` + `settings.json` |
| `bin/jaga-db` — hook pemblokir perintah DB berbahaya untuk Claude & Qwen (aktif juga di `--yolo`) | `~/.claude/bin/` + hook di kedua `settings.json` |
| `claude/CLAUDE.md` — aturan global Claude (kapan Qwen, brief, gerbang VERDIK) | `~/.claude/CLAUDE.md` |
| `qwen/QWEN.md` — aturan global Qwen | `~/.qwen/QWEN.md` |
| `qwen/settings.contoh.json` — kerangka konfigurasi model **tanpa host & kunci** | `~/.qwen/settings.json` (hanya bila belum ada) |

**Tidak ikut** (sengaja): kunci API, memori proyek Claude (`~/.claude/projects/*/memory`), log Qwen,
QWEN.md per proyek (itu sudah ikut repo proyek masing-masing).

## Server (pertama kali)

```bash
# 0. Pakai pengguna biasa, BUKAN root (Qwen --yolo bisa menjalankan perintah apa pun)
sudo apt install -y zsh python3 git            # Debian/Ubuntu (RHEL: dnf install zsh python3 git)
# Node.js ≥ 20 (mis. lewat nvm), lalu:
npm install -g @qwen-code/qwen-code            # teruji di 0.28.4
curl -fsSL https://claude.ai/install.sh | bash # Claude Code, lalu jalankan `claude` sekali untuk login

# 1. Ambil kit (repo publik — tanpa domain/kunci) lalu pasang + kredensial (hanya di server)
git clone https://github.com/farhanfaturohman/claude-qwen-kit ~/claude-qwen-kit
cd ~/claude-qwen-kit
QWEN_BASE_URL='https://<host-llm>/v1' QWEN_API_KEY='<kunci>' ./install.sh --uji
#   → ~/.qwen/settings.json (mode 600). Tanpa variabel ini settings.json yang sudah ada tak disentuh.

# 2. Uji koneksi Qwen sungguhan (murah)
cd /path/ke/proyek && echo "Jawab: OK" | QWEN_RINGAN=1 ~/.claude/bin/qwen-exec kritik
```
Server harus bisa menjangkau host LLM tersebut (cek firewall/proxy keluar).
Cara termudah: tempel **prompt pemasangan** (disimpan pemilik di luar repo, berisi host & kunci) ke
Claude Code di server — Claude menjalankan semua langkah di atas.

## Pengaturan yang bisa disesuaikan

**Saat pemasangan** (variabel lingkungan untuk `install.sh`; bila tak diberikan, nilai yang sudah ada dipertahankan):

| Variabel | Bawaan | Arti |
|---|---|---|
| `QWEN_BASE_URL`, `QWEN_API_KEY`, `QWEN_MODEL` | — / — / `flash-next-fp8` | kredensial & model (ditulis ke `~/.qwen/settings.json`) |
| `QWEN_RETRIES` | `3` | percobaan ulang API per permintaan (`generationConfig.maxRetries`) |
| `QWEN_COMPACT` | `0.5` | ambang ringkasan konteks otomatis (`context.autoCompactThreshold`, 0–1). Lebih kecil = konteks ramping & cepat; lebih besar = ingatan panjang |

**Saat menjalankan** `qwen-exec` (variabel lingkungan per panggilan):

| Variabel | Bawaan | Arti |
|---|---|---|
| `QWEN_AREA` | — | regex path yang boleh ditulis; di luar itu ditandai ⚠ LUAR |
| `QWEN_VERIFIKASI` | `1` | `0` = tanpa pemeriksa independen |
| `QWEN_PUTARAN` | `1` | maks putaran perbaikan otomatis (sensitif → 2) |
| `QWEN_PERBAIKAN` | `baru` | `baru` = perbaikan di sesi ramping (brief+patch+temuan); `lanjut` = lanjut sesi pelaksana |
| `QWEN_ULANG_JARINGAN` / `QWEN_JEDA_ULANG` | `1` / `60` | ulang otomatis bila koneksi putus / jeda detik |
| `QWEN_MAX_TURNS` / `QWEN_MAX_WALL` / `QWEN_MAX_TOOLS` | `60` / `20m` / `250` | batas per sesi Qwen (tugas besar: 150/45m/500) |
| `QWEN_RINGAN` | — | `1` = cek cepat tanpa baca AGENTS/QWEN.md & tanpa verifikasi |
| `QWEN_EKOR` | `1500` | byte tiap bagian laporan yang dicetak |

**TITIK CEK di brief:** bagian berjudul `TITIK CEK:` (diakhiri baris kosong) berisi 2–6 butir terukur.
Pelaksana melapor `CEK n: ✓/✗ — bukti`, dan pemeriksa wajib menilai setiap butir. Satu ✗ memaksa
perbaikan otomatis walau pemeriksa menulis LULUS. Keluarannya memuat `TITIK_CEK (pemeriksa terakhir): a ✓ · b ✗ dari n titik`.
Butir yang diawali `$ ` (misalnya `1. $ grep -q x path`) **dijalankan mesin** (`bin/qwen-cekmesin`,
lewat jaga-db dulu), dan ✗ memaksa perbaikan. Kalau semua butir berupa `$`, semuanya lolos, dan patch
≤ `QWEN_SEPELE_BARIS` (bawaan 20) baris, hasilnya `VERDIK=LULUS_MESIN` tanpa sesi pemeriksa Qwen. Jalur
pintas ini hanya berlaku bila `QWEN_AREA` diisi dan semua file yang berubah ada di dalam area tersebut
(cache atau bytecode diabaikan).
Cek mesin hanya menerima perintah **baca**. Perintah yang menulis (redirect `>`, `rm`, `sed -i`,
`find -delete`, `os.remove` di `python -c`, dll.) ditandai `⊘`. Tanda ini berarti brief yang perlu
dibetulkan; tidak memaksa perbaikan. Ada juga jaring pengaman: file kotor dan file baru dari sesi itu
disalin sebelum cek, file bersih dipulihkan dari HEAD, dan sampingan cek dihapus. Hasilnya, cek tidak
pernah merusak pekerjaan (teruji juga saat ada `index.lock`). File untracked lama milik pengguna hanya
diberi peringatan `!!` bila berubah.

**v5, otomatis di setiap panggilan:**
- **Peta otomatis** (`bin/qwen-peta`, tanpa LLM): `git grep` untuk path, kelas, view, rute, dan `kode` yang
  disebut di brief. Hasilnya berupa file:baris yang ditempel ke prompt, jadi Qwen tidak perlu menjelajah.
  Matikan dengan `QWEN_PETA=0`.
- **Alat ramping**: alat non-kode (cron, agent, web, memori, dll.) dibuang, sehingga sekitar 31 alat menjadi 8.
  Token per giliran turun sekitar 23% (terukur 16,2rb → 12,5rb). `QWEN_ALAT=penuh` mengembalikannya.
- **Metrik** (`bin/qwen-metrik`): baris `METRIK:` per tahap di keluaran berisi menit, giliran, alat, alat
  sebelum tulis pertama, dan token. Riwayatnya ada di `~/.claude/qwen-logs/metrik.csv`.
- **Hemat panggilan**: penyebab lambat adalah jumlah panggilan model (masing-masing ±10–25 detik), bukan
  besar file. Pelaksana diminta menggabungkan perintah baca dalam satu shell, membuat beberapa edit
  dalam satu respons, dan membaca file besar dengan offset. Tahap yang melewati `QWEN_BESAR` (bawaan 40)
  giliran memunculkan `⚠ TUGAS BESAR` di keluaran, sebagai tanda brief berikutnya perlu dipecah.
- **Log uji terpisah**: `QWEN_LOGDIR` (dipakai `uji.sh`), jadi log Qwen palsu tidak mencemari
  `~/.claude/qwen-logs`.
- **Mode worktree** `QWEN_WORKTREE=1`: Qwen bekerja di git worktree terpisah. Basisnya working tree saat ini
  (termasuk perubahan yang belum di-commit), vendor di-clone, dan `.env` di-symlink. Di akhir, patch
  diterapkan ke folder asli. Kalau konflik, folder asli tidak disentuh dan worktree disimpan untuk revisi
  (`QWEN_WORKTREE=<path>`). Cocok untuk menjalankan beberapa brief kecil serentak. File untracked tidak ikut.

Pelaksana juga diarahkan kerja cepat: langsung ke file sasaran, jelajah ±8 baca, dan menyimpan bertahap
supaya hasil parsial tetap ada walau waktu habis.

**Judul tab terminal:** selama Qwen yang diluncurkan sesi Claude itu berjalan, judul tab menjadi
`⏳ Qwen <tahap> <durasi> · <proyek>`; setelah selesai kembali `✳ <proyek>`. Hanya tab pemilik sesi
yang berubah. Matikan dengan `"env": {"QWEN_JUDUL": "0"}` di `~/.claude/settings.json`.
(VS Code: judul dari proses tampil bila `terminal.integrated.tabs.title` memuat `${sequence}`.)

Pagar keamanan (larangan commit/push/tulis DB/destruktif) dikirim lewat `--append-system-prompt`,
jadi tetap berlaku walau konteks diringkas atau sesi dilanjutkan.

**Blokir teknis perintah DB berbahaya** (`bin/jaga-db`, hook `PreToolUse` di `~/.claude/settings.json`
untuk `Bash` dan di `~/.qwen/settings.json` untuk `run_shell_command`). Hook ini tetap aktif walau
Qwen `--yolo` atau Claude bypass permissions. Perintah ditolak (exit 2) dan model diminta melapor ke pengguna:

| Ditolak | Tetap boleh |
|---|---|
| `artisan migrate` (tanpa `--pretend`), `migrate:fresh/refresh/reset/rollback/install`, `db:wipe`, `schema:drop`, `db:seed`, `--seed` | `migrate:status`, `migrate --pretend` |
| SQL `DROP DATABASE/TABLE/SCHEMA/VIEW`, `TRUNCATE`, `ALTER TABLE … DROP`, `DELETE FROM` tanpa `WHERE` | `SELECT`, `DELETE … WHERE` |
| `Schema::drop*`, `->truncate()`, `dropAllTables`, `DB::unprepared`, `mysqladmin drop`, `dropdb`, `FLUSHALL/FLUSHDB` | |
| `phpunit`/`pest`/`artisan test` selain suite Unit (RefreshDatabase mengosongkan DB) | `--testsuite Unit`, `tests/Unit/…` |

Pencocokan memakai teks perintah, jadi ada juga positif palsu, misalnya `grep "migrate:fresh"` lewat
shell (pakai alat Grep bawaan sebagai gantinya). Uji manual:
`echo '{"tool_input":{"command":"php artisan db:wipe"}}' | ~/.claude/bin/jaga-db; echo $?` → `2`.
Pola ada di `ATURAN` dalam `bin/jaga-db`; sunting di sana lalu `./install.sh` ulang.
Ini lapisan pengaman terhadap kelalaian model, **bukan** sandbox. Lapisan terkuat tetap user DB read-only.

## Memperbarui

- **Di mesin utama** setelah mengubah pembungkus/aturan: `./ambil.sh` → tinjau `git diff` → commit & push.
- **Di server**: `cd ~/claude-qwen-kit && git pull && ./install.sh`.
  Pemasangan memakai file sementara + `mv`, jadi aman walau ada sesi Qwen yang sedang berjalan;
  versi lama dicadangkan di `~/.claude/.cadangan-kit/<waktu>/`.

## Catatan keamanan untuk server produksi

- `--yolo` artinya Qwen menjalankan perintah shell tanpa bertanya. Pagar di pembungkus (larangan
  commit/push/migrate/tulis DB, DB = PRODUKSI, tes hanya Unit) adalah **instruksi**, bukan sandbox.
  Di server produksi, lapisan teknisnya:
  - pengguna Linux terpisah tanpa sudo, pemilik hanya folder kerja;
  - kerja di **salinan/clone staging**, bukan folder yang dilayani web server;
  - bila memungkinkan, `.env` di salinan itu memakai **user DB read-only**.
- Kunci API hanya di `~/.qwen/settings.json` (mode 600). `.gitignore` kit menolak `settings.json`,
  log, `*.progress`, dan berkas `prompt-*`.
- Repo ini publik: **jangan pernah** commit host LLM, kunci, `.env`, atau log. Kredensial hanya lewat
  variabel lingkungan saat `install.sh`.
