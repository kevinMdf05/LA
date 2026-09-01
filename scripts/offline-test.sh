#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# KAI-EXEC-004 — Vérification de l'aptitude au vol.
#
# Ce que ce script PEUT prouver : que tout ce qui est nécessaire est sur le
# disque, qu'aucune dépendance ne se résout en ligne, que la génération et
# les embeddings fonctionnent localement.
#
# Ce qu'il NE PEUT PAS prouver : qu'un redémarrage à froid sans réseau
# fonctionne.  Ce test-là est manuel et il est décrit dans OFFLINE_RUNBOOK.md
# section A.  Ne pas confondre les deux, sinon on part en vol avec une
# fausse assurance (R-007).
# ---------------------------------------------------------------------------

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

kai_load_env
kai_mkdirs
title "KAI-EXEC-004 — Test d'aptitude au vol"

PASS=0; FAIL=0; WARN_N=0
check_ok()   { ok "$1";   PASS=$((PASS+1)); }
check_fail() { err "$1";  FAIL=$((FAIL+1)); }
check_warn() { warn "$1"; WARN_N=$((WARN_N+1)); }

# --- 0. Contexte réseau ----------------------------------------------------
title "0. Contexte"
if kai_http_ok "https://ollama.com" 4; then
  check_warn "Le Mac est ACTUELLEMENT EN LIGNE."
  log "    Ce test vérifie l'autonomie des composants, mais il ne remplace pas"
  log "    le test à froid sans réseau (OFFLINE_RUNBOOK.md, section A)."
else
  check_ok "Aucune connexion sortante détectée — conditions proches du vol."
fi

# --- 1. Modèles sur le disque ----------------------------------------------
title "1. Modèles présents localement"
if have ollama; then
  for role_tag in "principal:$KAI_MODEL_PRIMARY" "secours:$KAI_MODEL_FALLBACK" "embeddings:$KAI_MODEL_EMBEDDING"; do
    role="${role_tag%%:*}"; tag="${role_tag#*:}"
    if ollama list 2>/dev/null | awk '{print $1}' | grep -qx "$tag"; then
      check_ok "$role : $tag"
    else
      check_fail "$role : $tag ABSENT — bloquant en vol (R-002)"
    fi
  done
else
  check_fail "Ollama absent."
fi

# --- 2. Aucune résolution de version en ligne ------------------------------
title "2. Rien ne se résout en ligne au démarrage"
if [ -x "$KAI_ROOT/.venv/bin/open-webui" ]; then
  check_ok "Open WebUI est un exécutable local (.venv), pas 'uvx ...@latest'."
else
  check_fail "Open WebUI absent de .venv — 'make install' n'a pas été fait."
fi

if [ -f "$KAI_ROOT/infra/requirements.lock" ]; then
  check_ok "Dépendances Python verrouillées (infra/requirements.lock)."
else
  check_warn "Pas de requirements.lock — réassemblage identique non garanti (R-006)."
fi

# Un tag flottant dans la configuration réintroduit une dépendance réseau.
if grep -rnE '(^|[^a-z])(:latest|:main)([^a-z]|$)' "$KAI_ROOT/.env" \
     "$KAI_ROOT/scripts" "$KAI_ROOT/infra" 2>/dev/null \
     | grep -v '^\s*#' | grep -q .; then
  check_fail "Un tag flottant (:latest / :main) subsiste dans la configuration."
else
  check_ok "Aucun tag flottant dans la configuration."
fi

# --- 3. Variables du mode hors ligne ---------------------------------------
title "3. Mode hors ligne activé"
for var in HF_HUB_OFFLINE TRANSFORMERS_OFFLINE; do
  value="$(eval "printf '%s' \"\${$var:-}\"")"
  if [ "$value" = "1" ]; then
    check_ok "$var=1"
  else
    check_fail "$var n'est pas à 1 — un composant peut tenter un téléchargement."
  fi
done

# --- 4. Services --------------------------------------------------------
title "4. Services"
if kai_http_ok "$(kai_ollama_url)/api/tags" 3; then
  check_ok "Ollama répond sur $(kai_ollama_url)"
else
  check_fail "Ollama ne répond pas — lancez 'make start'."
fi
if kai_http_ok "$(kai_webui_url)/health" 3; then
  check_ok "Open WebUI répond sur $(kai_webui_url)"
else
  check_warn "Open WebUI ne répond pas — lancez 'make start'."
fi

# --- 5. Génération réelle, hors ligne ---------------------------------------
# Une réponse produite est la seule preuve qui compte ; « le service répond »
# ne prouve pas qu'un modèle peut générer (§13).
title "5. Génération locale réelle"
if have curl && kai_http_ok "$(kai_ollama_url)/api/tags" 3; then
  START="$(date +%s)"
  RESP="$(curl -fsS --max-time 180 "$(kai_ollama_url)/api/generate" \
    -d "{\"model\":\"$KAI_MODEL_PRIMARY\",\"prompt\":\"Réponds uniquement par le mot: PRET\",\"stream\":false,\"options\":{\"num_ctx\":$KAI_NUM_CTX,\"num_predict\":16}}" \
    2>/dev/null || true)"
  ELAPSED=$(( $(date +%s) - START ))
  if printf '%s' "$RESP" | grep -q '"response"'; then
    check_ok "Le modèle a généré une réponse en ${ELAPSED} s."
    TEXT="$(printf '%s' "$RESP" | sed -n 's/.*"response":"\([^"]*\)".*/\1/p' | head -c 60)"
    [ -n "$TEXT" ] && log "    Réponse : $TEXT"
    [ "$ELAPSED" -gt 60 ] && check_warn "Génération lente (${ELAPSED} s) — envisagez $KAI_MODEL_FALLBACK."
  else
    check_fail "Aucune réponse générée par $KAI_MODEL_PRIMARY."
  fi
else
  check_warn "Génération non testée (curl ou Ollama indisponible)."
fi

# --- 6. Embeddings — le point faible classique du RAG hors ligne -----------
title "6. Embeddings locaux (RAG hors ligne)"
if have curl && kai_http_ok "$(kai_ollama_url)/api/tags" 3; then
  EMB="$(curl -fsS --max-time 60 "$(kai_ollama_url)/api/embed" \
    -d "{\"model\":\"$KAI_MODEL_EMBEDDING\",\"input\":\"test hors ligne\"}" \
    2>/dev/null || true)"
  if printf '%s' "$EMB" | grep -q '"embeddings"'; then
    check_ok "Le modèle d'embeddings répond localement."
  else
    check_fail "Embeddings indisponibles — le RAG sera cassé en vol (R-002)."
  fi
else
  check_warn "Embeddings non testés."
fi

# --- 7. Persistance --------------------------------------------------------
title "7. Persistance des données"
if [ -d "$KAI_ROOT/data" ]; then
  check_ok "data/ existe — conversations et index survivront au redémarrage."
else
  check_warn "data/ absent — KAI n'a probablement jamais été lancé."
fi

# --- Verdict ---------------------------------------------------------------
title "Résultat"
log ""
log "  Réussis : $PASS   ·   Échecs : $FAIL   ·   Avertissements : $WARN_N"
log ""

REPORT="$KAI_REPORT_DIR/offline-test-$(kai_timestamp).md"
{
  printf '# Test d aptitude au vol — KAI-EXEC-004\n\n'
  printf 'Exécuté le %s\n\n' "$(kai_iso_date)"
  printf 'Réussis : %s · Échecs : %s · Avertissements : %s\n\n' "$PASS" "$FAIL" "$WARN_N"
  printf 'Ce rapport ne couvre PAS le redémarrage à froid sans réseau,\n'
  printf 'qui reste manuel (OFFLINE_RUNBOOK.md section A).\n'
} > "$REPORT"

if [ "$FAIL" -gt 0 ]; then
  err "RÉSULTAT : NON PRÊT POUR LE VOL — $FAIL contrôle(s) en échec."
  log ""
  log "  Corrigez les points marqués ✗ ci-dessus, puis relancez."
  exit 1
fi

if [ "$WARN_N" -gt 0 ]; then
  warn "RÉSULTAT : PRÊT POUR LE VOL, avec $WARN_N réserve(s)."
else
  ok "RÉSULTAT : PRÊT POUR LE VOL"
fi

log ""
warn "Il reste UN test que ce script ne peut pas faire à votre place :"
log ""
log "    couper le Wi-Fi ET le partage de connexion,"
log "    REDÉMARRER le Mac, puis 'make start' et poser une question."
log ""
info "Procédure complète : OFFLINE_RUNBOOK.md, section A."
