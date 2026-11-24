# Kit Claude + Qwen

Alur kerja hemat kuota: **Claude = otak** (memutuskan, menulis brief, gerbang akhir), **Qwen = tangan
& mata** (menjelajah, menulis, menguji, memeriksa silang). Kit ini memasang alur yang sama di mesin
mana pun: laptop, server, atau VM.

| Isi | Dipasang ke |
|---|---|
| `bin/qwen-exec` — pembungkus: pelaksana → pemeriksa independen → perbaikan otomatis | `~/.claude/bin/` |
| `bin/qwen-saring.py`, `qwen-awasi`, `qwen-ikuti` — saringan progres & pemantau | `~/.claude/bin/` |
| `bin/qwen-status` — status line progres Qwen (lokal, **nol token Claude**) | `~/.claude/bin/` + `settings.json` |
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

Pagar keamanan (larangan commit/push/tulis DB/destruktif) dikirim lewat `--append-system-prompt`,
jadi tetap berlaku walau konteks diringkas atau sesi dilanjutkan.

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
