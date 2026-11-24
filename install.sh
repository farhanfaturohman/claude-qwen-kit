#!/usr/bin/env bash
# Pasang kit Claude + Qwen ke akun pengguna saat ini (Mac/Linux). Aman diulang (idempoten).
#   ./install.sh            pasang/perbarui
#   ./install.sh --uji      pasang lalu jalankan uji pembungkus (qwen palsu, tanpa biaya LLM)
#   QWEN_BASE_URL=https://.../v1 QWEN_API_KEY=... [QWEN_MODEL=flash-next-fp8] ./install.sh
#                           sekalian tulis kredensial Qwen ke ~/.qwen/settings.json (mode 600)
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
STAMP=$(date +%Y%m%d-%H%M%S)
CAD="$HOME/.claude/.cadangan-kit/$STAMP"
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
info() { printf '  • %s\n' "$*"; }
awas() { printf '  \033[33m⚠\033[0m %s\n' "$*"; }

echo "== Prasyarat"
kurang=0
for c in zsh python3 git; do
  if command -v "$c" >/dev/null; then ok "$c"; else awas "$c TIDAK ADA (wajib)"; kurang=1; fi
done
[[ $kurang == 1 ]] && { echo "Pasang dulu, mis. Debian/Ubuntu: sudo apt install -y zsh python3 git"; exit 1; }
for c in node qwen claude; do
  if command -v "$c" >/dev/null; then ok "$c"; else awas "$c belum ada — lihat README §Server"; fi
done
command -v uuidgen >/dev/null || info "uuidgen tak ada — pembungkus memakai cadangan python3 (tidak masalah)"
[[ "$(id -u)" == 0 ]] && awas "Berjalan sebagai root: Qwen --yolo bisa menjalankan perintah apa pun. Sebaiknya pakai pengguna biasa."

# salin atomik: tulis ke file sementara lalu mv (proses yang sedang jalan tetap memegang file lama)
pasang() {  # $1 sumber  $2 tujuan  $3 mode
  local src=$1 dst=$2
  mkdir -p "$(dirname "$dst")"
  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then info "sama: ${dst/#$HOME/~}"; return; fi
  if [[ -f "$dst" ]]; then mkdir -p "$CAD"; cp -p "$dst" "$CAD/$(basename "$dst")"; fi
  cp "$src" "$dst.kit-tmp"; chmod "${3:-644}" "$dst.kit-tmp"; mv -f "$dst.kit-tmp" "$dst"
  ok "pasang: ${dst/#$HOME/~}"
}

echo "== Pembungkus (~/.claude/bin)"
for f in "$KIT"/bin/*; do pasang "$f" "$HOME/.claude/bin/$(basename "$f")" 755; done
zsh -n "$HOME/.claude/bin/qwen-exec" && ok "qwen-exec lolos cek sintaks"
mkdir -p "$HOME/.claude/qwen-logs"

echo "== Aturan global Claude (~/.claude/CLAUDE.md)"
pasang "$KIT/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

echo "== Status line progres Qwen (~/.claude/settings.json)"
python3 - "$HOME/.claude/settings.json" <<'PY'
import json, os, sys
p = sys.argv[1]
d = json.load(open(p)) if os.path.exists(p) and os.path.getsize(p) else {}
mau = {"type": "command", "command": "~/.claude/bin/qwen-status", "padding": 0, "refreshInterval": 5}
lama = d.get("statusLine")
if lama == mau:
    print("  • sama: statusLine")
else:
    if lama and "qwen-status" not in json.dumps(lama):
        print("  ⚠ statusLine lama diganti (cadangan: settings.json.bak-kit):", json.dumps(lama)[:120])
        if os.path.exists(p):
            open(p + ".bak-kit", "w").write(open(p).read())
    d["statusLine"] = mau
    os.makedirs(os.path.dirname(p), exist_ok=True)
    json.dump(d, open(p, "w"), indent=2, ensure_ascii=False)
    print("  ✓ statusLine qwen-status dipasang (refresh 5 dtk)")
PY

echo "== Qwen (~/.qwen)"
pasang "$KIT/qwen/QWEN.md" "$HOME/.qwen/QWEN.md"
if [[ -n "${QWEN_API_KEY:-}" ]]; then
  # Kredensial dari lingkungan (prompt/pemasang): tulis ke ~/.qwen/settings.json (600), tak pernah ke repo.
  [[ -z "${QWEN_BASE_URL:-}" ]] && { awas "QWEN_API_KEY diberikan tanpa QWEN_BASE_URL"; exit 1; }
  mkdir -p "$HOME/.qwen"
  [[ -f "$HOME/.qwen/settings.json" ]] && { mkdir -p "$CAD"; cp -p "$HOME/.qwen/settings.json" "$CAD/qwen-settings.json"; chmod 600 "$CAD/qwen-settings.json"; }
  umask 077
  python3 - "$KIT/qwen/settings.contoh.json" "$HOME/.qwen/settings.json" <<'PY'
import json, os, sys
contoh = json.load(open(sys.argv[1])); p = sys.argv[2]
d = json.load(open(p)) if os.path.exists(p) and os.path.getsize(p) else {}
url, kunci = os.environ["QWEN_BASE_URL"].rstrip("/"), os.environ["QWEN_API_KEY"]
model = os.environ.get("QWEN_MODEL") or contoh["model"]["name"]
prov = json.loads(json.dumps(contoh["modelProviders"]["openai"][0])); prov["id"] = model; prov["baseUrl"] = url
envkey = prov["envKey"]
daftar = [m for m in d.setdefault("modelProviders", {}).setdefault("openai", []) if m.get("id") != model]
d["modelProviders"]["openai"] = [prov] + daftar
d.setdefault("security", {}).setdefault("auth", {})["selectedType"] = "openai"
d["model"] = {"name": model, "baseUrl": url}
d.setdefault("$version", contoh.get("$version", 4))
d.setdefault("memory", contoh["memory"])
d.setdefault("env", {})[envkey] = kunci
json.dump(d, open(p, "w"), indent=2, ensure_ascii=False)
print(f"  ✓ kredensial Qwen ditulis: model={model} url={url} kunci=***{kunci[-4:]}")
PY
  chmod 600 "$HOME/.qwen/settings.json"
elif [[ -f "$HOME/.qwen/settings.json" ]]; then
  info "~/.qwen/settings.json sudah ada — tidak disentuh"
else
  mkdir -p "$HOME/.qwen"
  cp "$KIT/qwen/settings.contoh.json" "$HOME/.qwen/settings.json"; chmod 600 "$HOME/.qwen/settings.json"
  awas "~/.qwen/settings.json dibuat dari contoh — isi baseUrl & kunci (ulang dengan QWEN_BASE_URL/QWEN_API_KEY)"
fi
if grep -q '<ISI_' "$HOME/.qwen/settings.json" 2>/dev/null; then awas "kunci API Qwen belum diisi"; fi

echo "== Setelan kinerja Qwen (ubah lewat QWEN_RETRIES / QWEN_COMPACT, atau langsung di ~/.qwen/settings.json)"
python3 - "$HOME/.qwen/settings.json" <<'PY'
import json, os, sys
p = sys.argv[1]
if not os.path.exists(p):
    sys.exit(0)
d = json.load(open(p)); ubah = []
r_env, c_env = os.environ.get("QWEN_RETRIES"), os.environ.get("QWEN_COMPACT")
for m in d.get("modelProviders", {}).get("openai", []):
    if m.get("id") == d.get("model", {}).get("name"):
        g = m.setdefault("generationConfig", {})
        if r_env or "maxRetries" not in g or g.get("maxRetries", 0) < 2:
            g["maxRetries"] = int(r_env or 3); ubah.append(f"maxRetries={g['maxRetries']}")
ctx = d.setdefault("context", {})
if c_env or "autoCompactThreshold" not in ctx:
    ctx["autoCompactThreshold"] = float(c_env or 0.5); ubah.append(f"autoCompactThreshold={ctx['autoCompactThreshold']}")
if ubah:
    json.dump(d, open(p, "w"), indent=2, ensure_ascii=False); os.chmod(p, 0o600)
    print("  ✓ " + ", ".join(ubah))
else:
    print("  • sudah diatur (nilai milikmu dipertahankan)")
PY

[[ -d "$CAD" ]] && info "versi lama dicadangkan di ${CAD/#$HOME/~}"

if [[ "${1:-}" == --uji ]]; then
  echo "== Uji pembungkus (qwen palsu)"
  "$KIT/uji.sh"
fi
echo "Selesai. Buka sesi Claude Code baru agar CLAUDE.md & status line terbaca."
