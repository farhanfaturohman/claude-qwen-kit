#!/usr/bin/env python3
"""Saring stream-json Qwen menjadi baris progres ringkas (dibaca Claude secara langsung).

Pakai: qwen ... --output-format stream-json | qwen-saring.py <log.jsonl> <progres.txt>
- Semua event mentah disimpan ke <log.jsonl>.
- Setiap event penting jadi SATU baris pendek di <progres.txt> (di-flush per baris).
- Di stdout dicetak laporan akhir Qwen (teks terakhir asisten) + pemakaian token.
"""
import json
import sys

log_path, prog_path = sys.argv[1], sys.argv[2]
log = open(log_path, "a", buffering=1)
prog = open(prog_path, "a", buffering=1)


def pendek(s, n):
    s = " ".join(str(s).split())
    return s if len(s) <= n else s[: n - 1] + "…"


def tulis(baris):
    prog.write(baris + "\n")
    prog.flush()


def arg_tool(inp):
    if not isinstance(inp, dict):
        return pendek(inp, 120)
    for k in ("command", "file_path", "path", "pattern", "query", "url"):
        if k in inp:
            extra = ""
            if k == "pattern" and "path" in inp:
                extra = f" @ {inp['path']}"
            return pendek(f"{inp[k]}{extra}", 160)
    return pendek(json.dumps(inp, ensure_ascii=False), 120)


teks_terakhir = []
hasil = None
for raw in sys.stdin:
    log.write(raw)
    try:
        d = json.loads(raw)
    except ValueError:
        if raw.strip():
            tulis("⚠ " + pendek(raw, 200))
        continue
    t = d.get("type")
    m = d.get("message") or {}
    isi = m.get("content") if isinstance(m, dict) else None
    if t == "assistant" and isinstance(isi, list):
        ada_tool = False
        for b in isi:
            bt = b.get("type")
            if bt == "thinking":
                tulis("💭 " + pendek(b.get("thinking") or b.get("text") or "", 220))
            elif bt == "text":
                txt = b.get("text") or ""
                teks_terakhir.append(txt)
                tulis("📝 " + pendek(txt, 220))
            elif bt == "tool_use":
                ada_tool = True
                tulis(f"🔧 {b.get('name')}: {arg_tool(b.get('input'))}")
        if ada_tool:
            teks_terakhir = []  # laporan akhir = teks setelah tool terakhir
    elif t == "user" and isinstance(isi, list):
        for b in isi:
            if b.get("type") == "tool_result":
                c = b.get("content")
                if isinstance(c, list):
                    c = " ".join(x.get("text", "") for x in c if isinstance(x, dict))
                tanda = "✗" if b.get("is_error") else "✓"
                tulis(f"  {tanda} {pendek(c or '', 140)}")
    elif t == "result":
        hasil = d

if hasil:
    u = hasil.get("usage") or {}
    err = (hasil.get("error") or {}).get("message", "")
    tulis(
        f"■ HASIL {hasil.get('subtype')} turns={hasil.get('num_turns')} "
        f"token_qwen={u.get('total_tokens')} {pendek(err, 200)}"
    )
print("\n\n".join(teks_terakhir).strip() or "(Qwen tidak menulis laporan akhir — lihat progres/log)")
if hasil:
    u = hasil.get("usage") or {}
    print(f"\n[qwen: {hasil.get('subtype')}, turns={hasil.get('num_turns')}, token={u.get('total_tokens')}]")
    if hasil.get("is_error"):
        print("!! " + str((hasil.get("error") or {}).get("message", ""))[:500])
