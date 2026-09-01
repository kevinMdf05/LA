#!/usr/bin/env python3
"""Harnais d'évaluation des modèles locaux — KAI-MISSION-001 §5 et §14.

Mesure ce qui est mesurable automatiquement :
  - temps au premier token (TTFT)
  - tokens par seconde
  - durée totale et durée de chargement du modèle
  - mémoire résidente maximale observée du processus Ollama

Ne note PAS la qualité automatiquement.  Faire noter des réponses par le
modèle qu'on évalue, ou par un autre modèle non validé, produit un score qui
mesure surtout la complaisance du juge.  La grille de `rubric.md` est remplie
à la main, une fois, et conservée ; c'est plus lent et c'est plus fiable.

Dépendances : bibliothèque standard uniquement — le harnais doit tourner
en vol, sans pip install.

Usage :
    python3 tests/evaluation/run_eval.py
    python3 tests/evaluation/run_eval.py --model qwen3.5:2b-q4_K_M
    python3 tests/evaluation/run_eval.py --limit 5 --num-ctx 8192
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
RESULTS_DIR = HERE / "results"


def load_env() -> dict:
    """Lit .env puis .env.example, sans écraser l'environnement réel."""
    values: dict[str, str] = {}
    for name in (".env.example", ".env"):
        path = ROOT / name
        if not path.exists():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, val = line.partition("=")
            values[key.strip()] = val.strip()
    values.update({k: v for k, v in os.environ.items() if k.startswith("KAI_")})
    return values


def ollama_url(env: dict) -> str:
    host = env.get("KAI_OLLAMA_HOST", "127.0.0.1")
    port = env.get("KAI_OLLAMA_PORT", "11434")
    return f"http://{host}:{port}"


def ollama_alive(base: str) -> bool:
    try:
        with urllib.request.urlopen(f"{base}/api/tags", timeout=3):
            return True
    except (urllib.error.URLError, OSError):
        return False


def ollama_rss_mb() -> float | None:
    """Mémoire résidente du processus Ollama, en Mo.

    Best effort : `ps` diffère entre macOS et Linux, et le serveur peut tourner
    sous un autre nom. Retourne None plutôt qu'un chiffre inventé.
    """
    try:
        out = subprocess.run(
            ["ps", "-Ao", "rss,comm"],
            capture_output=True, text=True, timeout=5,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return None
    total_kb = 0
    for line in out.splitlines()[1:]:
        parts = line.split(None, 1)
        if len(parts) != 2:
            continue
        rss, comm = parts
        if "ollama" in comm.lower():
            try:
                total_kb += int(rss)
            except ValueError:
                pass
    return round(total_kb / 1024, 1) if total_kb else None


def ask(base: str, model: str, prompt: str, num_ctx: int, max_tokens: int,
        timeout: int) -> dict:
    """Une génération en streaming, instrumentée."""
    payload = json.dumps({
        "model": model,
        "prompt": prompt,
        "stream": True,
        "options": {"num_ctx": num_ctx, "num_predict": max_tokens,
                    "temperature": 0.2, "seed": 42},
    }).encode("utf-8")

    req = urllib.request.Request(
        f"{base}/api/generate", data=payload,
        headers={"Content-Type": "application/json"},
    )

    started = time.perf_counter()
    ttft = None
    chunks: list[str] = []
    final: dict = {}
    peak_rss = ollama_rss_mb()

    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            for raw in resp:
                if not raw.strip():
                    continue
                try:
                    obj = json.loads(raw.decode("utf-8"))
                except json.JSONDecodeError:
                    continue
                piece = obj.get("response", "")
                if piece and ttft is None:
                    ttft = time.perf_counter() - started
                if piece:
                    chunks.append(piece)
                    # Échantillonne la mémoire pendant la génération : le pic
                    # arrive au chargement, pas à la fin.
                    if len(chunks) % 32 == 0:
                        cur = ollama_rss_mb()
                        if cur and (peak_rss is None or cur > peak_rss):
                            peak_rss = cur
                if obj.get("done"):
                    final = obj
    except (urllib.error.URLError, OSError, TimeoutError) as exc:
        return {"ok": False, "error": f"{type(exc).__name__}: {exc}",
                "elapsed_s": round(time.perf_counter() - started, 2)}

    elapsed = time.perf_counter() - started
    eval_count = final.get("eval_count") or 0
    eval_ns = final.get("eval_duration") or 0
    tok_per_s = round(eval_count / (eval_ns / 1e9), 2) if eval_count and eval_ns else None

    return {
        "ok": True,
        "answer": "".join(chunks).strip(),
        "ttft_s": round(ttft, 3) if ttft is not None else None,
        "elapsed_s": round(elapsed, 2),
        "tokens_out": eval_count,
        "tokens_per_s": tok_per_s,
        "load_s": round((final.get("load_duration") or 0) / 1e9, 2),
        "peak_ollama_rss_mb": peak_rss,
    }


def main() -> int:
    env = load_env()
    ap = argparse.ArgumentParser(description="Évaluation des modèles locaux KAI")
    ap.add_argument("--model", default=env.get("KAI_MODEL_PRIMARY", "qwen3.5:4b-q4_K_M"))
    ap.add_argument("--num-ctx", type=int, default=int(env.get("KAI_NUM_CTX", "4096")))
    ap.add_argument("--limit", type=int, default=0, help="n'exécuter que les N premières")
    ap.add_argument("--category", default="", help="filtrer sur une catégorie")
    ap.add_argument("--timeout", type=int, default=300)
    args = ap.parse_args()

    base = ollama_url(env)
    if not ollama_alive(base):
        print(f"✗ Ollama injoignable sur {base}.  Lancez : make start", file=sys.stderr)
        return 1

    questions = [json.loads(line) for line in
                 (HERE / "questions.jsonl").read_text(encoding="utf-8").splitlines()
                 if line.strip()]
    if args.category:
        questions = [q for q in questions if q["category"] == args.category]
    if args.limit:
        questions = questions[: args.limit]

    if not questions:
        print("✗ Aucune question à exécuter.", file=sys.stderr)
        return 1

    print(f"\nModèle   : {args.model}")
    print(f"Contexte : {args.num_ctx} tokens")
    print(f"Questions: {len(questions)}\n")

    results = []
    for i, q in enumerate(questions, 1):
        print(f"  [{i:2d}/{len(questions)}] {q['id']} ({q['category']}) … ",
              end="", flush=True)
        out = ask(base, args.model, q["prompt"], args.num_ctx,
                  q.get("max_tokens", 300), args.timeout)
        if out["ok"]:
            print(f"{out['elapsed_s']}s  TTFT {out['ttft_s']}s  "
                  f"{out['tokens_per_s']} tok/s")
        else:
            print(f"ÉCHEC — {out['error']}")
        results.append({**q, "result": out})

    # --- Agrégats ----------------------------------------------------------
    ok = [r["result"] for r in results if r["result"]["ok"]]
    def avg(key):
        vals = [r[key] for r in ok if r.get(key) is not None]
        return round(sum(vals) / len(vals), 2) if vals else None

    peaks = [r["peak_ollama_rss_mb"] for r in ok if r.get("peak_ollama_rss_mb")]
    summary = {
        "model": args.model,
        "num_ctx": args.num_ctx,
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "questions": len(results),
        "succeeded": len(ok),
        "failed": len(results) - len(ok),
        "avg_ttft_s": avg("ttft_s"),
        "avg_tokens_per_s": avg("tokens_per_s"),
        "avg_elapsed_s": avg("elapsed_s"),
        "peak_ollama_rss_mb": max(peaks) if peaks else None,
    }

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    slug = args.model.replace(":", "_").replace("/", "_")
    json_path = RESULTS_DIR / f"eval-{slug}-{stamp}.json"
    json_path.write_text(
        json.dumps({"summary": summary, "results": results},
                   ensure_ascii=False, indent=2),
        encoding="utf-8")

    md_path = RESULTS_DIR / f"eval-{slug}-{stamp}.md"
    lines = [
        f"# Évaluation — {args.model}", "",
        f"Exécutée le {summary['generated_at']} · contexte {args.num_ctx} tokens", "",
        "| Mesure | Valeur |", "|---|---|",
        f"| Questions | {summary['questions']} |",
        f"| Réussies (techniquement) | {summary['succeeded']} |",
        f"| Échecs | {summary['failed']} |",
        f"| TTFT moyen | {summary['avg_ttft_s']} s |",
        f"| Débit moyen | {summary['avg_tokens_per_s']} tok/s |",
        f"| Mémoire Ollama maximale | {summary['peak_ollama_rss_mb']} Mo |",
        "",
        "> « Réussie » signifie ici : une réponse a été produite sans erreur.",
        "> **Cela ne dit rien de sa qualité.** La notation se fait à la main",
        "> avec `rubric.md`, en remplissant la colonne « note » ci-dessous.",
        "", "## Réponses à noter", "",
    ]
    for r in results:
        res = r["result"]
        lines += [
            f"### {r['id']} — {r['category']}", "",
            f"**Question.** {r['prompt']}", "",
            f"**Attendu.** {r['expects']}", "",
            "**Réponse du modèle.**", "",
            "```", (res.get("answer") or f"[ÉCHEC] {res.get('error','')}"), "```", "",
            f"*{res.get('elapsed_s')} s · TTFT {res.get('ttft_s')} s · "
            f"{res.get('tokens_per_s')} tok/s*", "",
            "| Exactitude | Fidélité | Complétude | Abstention | Note /4 |",
            "|---|---|---|---|---|", "|  |  |  |  |  |", "",
        ]
    md_path.write_text("\n".join(lines), encoding="utf-8")

    print(f"\n  TTFT moyen ........ {summary['avg_ttft_s']} s")
    print(f"  Débit moyen ....... {summary['avg_tokens_per_s']} tok/s")
    print(f"  Mémoire Ollama max  {summary['peak_ollama_rss_mb']} Mo")
    print(f"\n✓ Résultats : {json_path}")
    print(f"✓ Grille à remplir à la main : {md_path}\n")

    if summary["peak_ollama_rss_mb"] and summary["peak_ollama_rss_mb"] > 6000:
        print("! Mémoire élevée (> 6 Go) sur une machine de 8 Go.")
        print("  Comparez avec le modèle de secours avant de trancher (D-004).\n")

    return 0 if summary["failed"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
