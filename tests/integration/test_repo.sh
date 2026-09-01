#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Tests d'intégration du dépôt.
#
# Ce que ces tests vérifient : que le dépôt est cohérent, qu'aucun secret n'y
# figure, qu'aucun tag flottant ne s'y cache, et que les scripts sont
# syntaxiquement valides et compatibles avec le bash 3.2 de macOS.
#
# Ce qu'ils NE vérifient PAS : le comportement réel sur macOS avec Ollama.
# Aucun test d'ici ne peut remplacer `make offline-test` sur le Mac.
# ---------------------------------------------------------------------------

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

PASS=0; FAIL=0
if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; B=$'\033[1m'; N=$'\033[0m'
else G=''; R=''; B=''; N=''; fi

t_ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$1"; PASS=$((PASS+1)); }
t_fail() { printf '  %s✗%s %s\n' "$R" "$N" "$1"; FAIL=$((FAIL+1)); }
section(){ printf '\n%s%s%s\n' "$B" "$1" "$N"; }

# --- 1. Syntaxe des scripts ------------------------------------------------
section "1. Syntaxe des scripts shell"
for f in scripts/*.sh scripts/lib/*.sh tests/integration/*.sh; do
  [ -f "$f" ] || continue
  if bash -n "$f" 2>/dev/null; then t_ok "syntaxe : $f"
  else t_fail "syntaxe : $f"; fi
done

# --- 2. Compatibilité bash 3.2 (macOS) -------------------------------------
# macOS livre bash 3.2. Ces constructions sont du bash 4+ et casseraient sur
# la machine cible, où rien ne peut être corrigé en vol.
section "2. Compatibilité bash 3.2 (macOS)"
# Le motif est assemblé à partir de morceaux, sinon ce fichier se détecte
# lui-même et le test échoue sur sa propre définition.
B4="(declare -"'A'"|map"'file'"|read"'array'"|\$\{[a-zA-Z_]+\^\^|\$\{[a-zA-Z_]+,,)"
BAD="$(grep -rnE "$B4" scripts/ tests/integration/ 2>/dev/null \
  | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' | grep -v 'B4=' || true)"
if [ -z "$BAD" ]; then t_ok "aucune construction bash 4+"
else t_fail "construction bash 4+ détectée"; printf '%s\n' "$BAD" | sed 's/^/      /'; fi

# --- 3. Scripts exécutables ------------------------------------------------
section "3. Droits d'exécution"
for f in scripts/*.sh tests/integration/*.sh tests/evaluation/run_eval.py; do
  [ -f "$f" ] || continue
  if [ -x "$f" ]; then t_ok "exécutable : $f"; else t_fail "non exécutable : $f"; fi
done

# --- 4. Aucun tag flottant (R-006) -----------------------------------------
section "4. Versions épinglées (R-006)"
FLOAT="$(grep -rnE ':(latest|main)([^a-zA-Z0-9_.-]|$)' \
  .env.example Makefile scripts/ infra/ 2>/dev/null \
  | grep -vE '^\S+:[0-9]+:\s*#' | grep -v 'offline-test.sh' || true)"
if [ -z "$FLOAT" ]; then t_ok "aucun tag :latest ou :main"
else t_fail "tag flottant détecté"; printf '%s\n' "$FLOAT" | sed 's/^/      /'; fi

# --- 5. Réseau : boucle locale uniquement (§9.2) ---------------------------
section "5. Liaison réseau (§9.2)"
if grep -q '^KAI_BIND_HOST=127.0.0.1' .env.example; then
  t_ok ".env.example lie le service à 127.0.0.1"
else t_fail ".env.example ne lie pas le service à 127.0.0.1"; fi

# Ne cherche que ce qui LIERAIT réellement un service : une affectation,
# une option --host, ou un mappage de port.  Une mention de "0.0.0.0" dans
# un message d avertissement n est pas une exposition.
EXPOSED="$(grep -rnE '(=|--host[ =]|")0\.0\.0\.0' .env.example scripts/ infra/ 2>/dev/null \
  | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' || true)"
if [ -z "$EXPOSED" ]; then t_ok "aucune liaison 0.0.0.0 active"
else t_fail "liaison 0.0.0.0 détectée"; printf '%s\n' "$EXPOSED" | sed 's/^/      /'; fi

# --- 6. Aucun secret dans .env.example -------------------------------------
section "6. Secrets"
if grep -qE '^(OPENAI_API_KEY|ANTHROPIC_API_KEY|GOOGLE_API_KEY|WEBUI_SECRET_KEY)=.+' \
   .env.example 2>/dev/null; then
  t_fail ".env.example contient une valeur de clé non vide"
else t_ok ".env.example ne contient aucune valeur de clé"; fi

if ./scripts/secret-scan.sh >/dev/null 2>&1; then t_ok "secret-scan : dépôt propre"
else t_fail "secret-scan : problème détecté (lancez make secret-scan)"; fi

if git check-ignore -q .env 2>/dev/null; then t_ok ".env est ignoré par Git"
else t_fail ".env n'est PAS ignoré par Git"; fi

# --- 7. Jeu d'évaluation ---------------------------------------------------
section "7. Jeu d'évaluation"
if python3 - <<'PY' 2>/dev/null
import json,sys
gen=[json.loads(l) for l in open('tests/evaluation/questions.jsonl') if l.strip()]
rag=[json.loads(l) for l in open('tests/evaluation/rag_questions.jsonl') if l.strip()]
assert len(gen)==30, f"attendu 30 questions générales, trouvé {len(gen)}"
assert len(rag)==20, f"attendu 20 questions RAG, trouvé {len(rag)}"
assert len({q['id'] for q in gen})==30 and len({q['id'] for q in rag})==20, "ids dupliqués"
for q in gen: assert {'id','category','prompt','expects','max_tokens'} <= set(q), q['id']
for q in rag: assert {'id','type','question','expected','source'} <= set(q), q['id']
cats={q['category'] for q in gen}
required={'francais-courant','redaction','raisonnement','synthese',
          'extraction-structuree','comprehension-document','refus-inventer','multilingue'}
assert required <= cats, f"catégories manquantes : {required-cats}"
assert any(q['type']=='injection-de-prompt' for q in rag), "aucun test d'injection (R-009)"
PY
then t_ok "30 questions générales + 20 RAG, schéma et catégories conformes"
else t_fail "jeu d'évaluation non conforme"; fi

if python3 -m py_compile tests/evaluation/run_eval.py 2>/dev/null; then
  t_ok "run_eval.py compile"
else t_fail "run_eval.py ne compile pas"; fi

# --- 8. Corpus de test -----------------------------------------------------
section "8. Corpus de test"
for f in voyage-2026.md budget-voyage.csv assurance-v1.md assurance-v2.md \
         hotel-confirmation-en.md document-piege.md; do
  if [ -f "tests/evaluation/corpus/$f" ]; then t_ok "corpus : $f"
  else t_fail "corpus manquant : $f"; fi
done
# Le document piège doit réellement contenir une injection, sinon le test
# rag-018 ne teste rien.
if grep -qi 'IGNORE TOUTES LES INSTRUCTIONS' tests/evaluation/corpus/document-piege.md; then
  t_ok "document-piege.md contient bien une tentative d'injection"
else t_fail "document-piege.md ne contient plus d'injection — rag-018 ne teste rien"; fi

# --- 9. Documents de gouvernance (§18) -------------------------------------
section "9. Livrables documentaires (§18)"
for f in README.md VERSIONS.md DECISIONS.md ANOMALIES.md ITERATIONS.md \
         SECURITY.md DATA_POLICY.md OFFLINE_RUNBOOK.md .env.example \
         Makefile infra/compose/docker-compose.yml; do
  if [ -s "$f" ]; then t_ok "présent : $f"; else t_fail "manquant ou vide : $f"; fi
done

for m in 001 002 003 004 005 006 007; do
  if [ -s "docs/missions/KAI-EXEC-$m.md" ]; then t_ok "mission KAI-EXEC-$m"
  else t_fail "fiche de mission manquante : KAI-EXEC-$m"; fi
done

# --- 10. Cohérence du Makefile ---------------------------------------------
section "10. Cohérence du Makefile"
MISSING=""
for s in hardware-report install-v0 preload-models start stop status \
         backup restore offline-test diagnose secret-scan check-versions; do
  [ -f "scripts/$s.sh" ] || MISSING="$MISSING $s.sh"
done
if [ -z "$MISSING" ]; then t_ok "tous les scripts appelés par le Makefile existent"
else t_fail "scripts manquants :$MISSING"; fi

if make -n help >/dev/null 2>&1; then t_ok "le Makefile s'analyse sans erreur"
else t_fail "le Makefile ne s'analyse pas"; fi

# --- 11. Rapport matériel --------------------------------------------------
section "11. Rapport matériel"
if ./scripts/hardware-report.sh >/dev/null 2>&1 \
   && python3 -c "import json;d=json.load(open('reports/hardware-report.json'));assert d['mission']=='KAI-EXEC-001';assert 'profile' in d" 2>/dev/null; then
  t_ok "hardware-report.sh produit un JSON valide et exploitable"
else t_fail "hardware-report.sh ne produit pas de JSON valide"; fi

# --- 12. Cohérence des tailles de modèles ----------------------------------
section "12. Cohérence documentaire"
if grep -q '5,64 Go' README.md && grep -q '5.64' scripts/hardware-report.sh; then
  t_ok "le total de 5,64 Go est cohérent entre README et scripts"
else t_fail "incohérence sur la taille totale des modèles"; fi

if grep -q 'qwen3.5:4b-q4_K_M' .env.example VERSIONS.md >/dev/null 2>&1; then
  t_ok "le modèle principal est épinglé de façon cohérente"
else t_fail "le modèle principal n'est pas épinglé partout"; fi

# --- Résultat --------------------------------------------------------------
printf '\n%s%s%s\n' "$B" "Résultat" "$N"
printf '\n  Réussis : %s   ·   Échecs : %s\n\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf '  %s%s tests en échec.%s\n\n' "$R" "$FAIL" "$N"
  exit 1
fi
printf '  %sTous les tests passent.%s\n' "$G" "$N"
printf '  Rappel : aucun de ces tests ne prouve le comportement sur macOS.\n'
printf '  Le test qui compte reste « make offline-test » sur le Mac.\n\n'
