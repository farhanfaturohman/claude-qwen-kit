# Aturan kerja global

## Bahasa & gaya
- Jawab dalam Bahasa Indonesia, ringkas, langsung ke hasil.
- Selesaikan tugas sampai tuntas: tulis script, JALANKAN, verifikasi hasilnya, perbaiki jika error. Jangan berhenti di "ini kodenya".

## Konteks pengguna
- Developer di lingkungan Kejaksaan RI. Stack: Laravel (PHP), Flutter, Nuxt/Vue, Python, MySQL/MariaDB.
- Data instansi bersifat sensitif: jangan kirim ke layanan eksternal, jangan buat contoh data yang menyerupai data asli.

## Konvensi kepegawaian (ASN/Kejaksaan)
- Golongan ditulis lengkap dengan ruang: "III/a", "III/b", "IV/a" (bukan "a"/"b").
- NIP 18 digit, simpan sebagai TEKS (bukan angka) agar tidak berubah jadi notasi ilmiah di Excel.
- Format tanggal Indonesia: "6 Oktober 2026". Rupiah: "Rp 1.250.000".

## Membuat dokumen
- Excel: openpyxl — header tebal + fill, freeze header, lebar kolom menyesuaikan isi, angka/NIP berformat benar.
- PDF: reportlab (atau weasyprint dari HTML untuk layout kompleks). Ukuran A4, margin wajar, judul di tengah.
- Word: python-docx. PowerPoint: python-pptx.
- Simpan script generator di samping file output supaya bisa dijalankan ulang.
- Setelah membuat file, verifikasi (buka ulang dengan library terkait / ekstrak teks PDF) sebelum menyatakan selesai.

## Coding
- Ikuti gaya kode yang sudah ada di proyek (penamaan, struktur, komentar).
- Baca file terkait sebelum mengedit. Jangan membaca file raksasa (dump SQL, log besar) secara utuh — pakai grep/head.
- Jangan commit/push atau menjalankan perintah destruktif (DROP, rm -rf, migrate:fresh) tanpa diminta.

## Basis data (aturan keras — berlaku di SEMUA proyek, SEMUA chat, tanpa pengecualian)
- **Tidak boleh ada `migrate:fresh`. Lagi.** Bukan "kalau perlu", bukan "kalau diminta" — tidak ada
  jalur yang boleh berakhir `migrate:fresh`: perintahnya langsung (opsi apa pun pun), `db:wipe`,
  `DROP DATABASE`/`DROP TABLE`, dan trait tes `RefreshDatabase` (di baliknya Laravel memanggil
  `migrate:fresh`). Alasan: 14-11-2026 satu tes Feature sementara memakai `RefreshDatabase` dan
  seluruh tabel `mysimkari_production` hilang (binlog OFF, tidak bisa replay).
- Jangan pernah menulis `use RefreshDatabase;` pada tes Laravel, termasuk tes sementara/jejak.
  Tes menulis baris berpola sendiri lalu menghapusnya, atau dibungkus transaksi manual
  (`DB::beginTransaction()` + `rollBack()` di tearDown).
- Kalau benar-benar butuh skema bersih: sqlite in-memory, atau DB scratch dengan nama yang jelas
  berbeda, dan arahkan lewat konfigurasi — jangan pernah mengandalkan koneksi default, karena di
  beberapa proyek koneksi default adalah basis data produksi.
- Sebelum perintah apa pun yang menulis atau mengubah skema, sebutkan lebih dulu koneksi + nama
  basis data tujuan yang dibaca dari berkas konfigurasi (`.env`, `phpunit.xml`, `config/database.php`).

## GitHub Copilot (delegasi)
- Tersedia skill `copilot-delegate` untuk melempar tugas ke GitHub Copilot CLI. Ikuti aturan di skill itu:
  hanya untuk tugas yang jelas lebih baik di Copilot, dan JANGAN PERNAH untuk data sensitif.
