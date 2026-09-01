#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Démarre la V0 : Ollama puis Open WebUI, tous deux liés à la boucle locale.
#
#   scripts/start.sh                 démarre tout
#   scripts/start.sh --ollama-only   démarre uniquement Ollama
#
# Réseau : rien n'écoute au-delà de 127.0.0.1 (§9.2, décision D-002).
# ---------------------------------------------------------------------------

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

kai_load_env
kai_mkdirs
LOG_DIR="$KAI_ROOT/logs"; mkdir -p "$LOG_DIR"

ONLY_OLLAMA=0
[ "${1:-}" = "--ollama-only" ] && ONLY_OLLAMA=1

# --- Garde-fou réseau ------------------------------------------------------
# Une liaison sur 0.0.0.0 exposerait le service à tout le réseau local.  Elle
# exige une décision explicite de Kevin (question Q-002), pas une variable
# d'environnement oubliée.
if [ "$KAI_BIND_HOST" != "127.0.0.1" ] && [ "$KAI_BIND_HOST" != "localhost" ]; then
  err "KAI_BIND_HOST vaut '$KAI_BIND_HOST' au lieu de 127.0.0.1."
  err "Cela exposerait KAI au réseau local — voir SECURITY.md §2 et Q-002."
  die "Démarrage refusé. Corrigez .env, ou tranchez Q-002 explicitement."
fi

# --- Ollama ----------------------------------------------------------------
start_ollama() {
  if kai_http_ok "$(kai_ollama_url)/api/tags" 3; then
    ok "Ollama déjà en service sur $(kai_ollama_url)"
    return 0
  fi
  have ollama || die "Ollama absent. Lancez 'make install'."

  info "Démarrage d'Ollama…"
  # Les trois variables ci-dessous sont la discipline mémoire du §5 :
  # un seul modèle chargé, aucun parallélisme, déchargement après inactivité.
  OLLAMA_HOST="$KAI_OLLAMA_HOST:$KAI_OLLAMA_PORT" \
  OLLAMA_NUM_PARALLEL="${OLLAMA_NUM_PARALLEL:-1}" \
  OLLAMA_MAX_LOADED_MODELS="${OLLAMA_MAX_LOADED_MODELS:-1}" \
  OLLAMA_KEEP_ALIVE="${OLLAMA_KEEP_ALIVE:-5m}" \
    nohup ollama serve >> "$LOG_DIR/ollama.log" 2>&1 &
  printf '%s' "$!" > "$KAI_RUN_DIR/ollama.pid"

  local i=0
  while [ "$i" -lt 30 ]; do
    if kai_http_ok "$(kai_ollama_url)/api/tags" 2; then
      ok "Ollama en service sur $(kai_ollama_url)"
      return 0
    fi
    i=$((i + 1))
    sleep 1
  done
  err "Ollama n'a pas répondu en 30 s. Voir $LOG_DIR/ollama.log"
  return 1
}

# --- Open WebUI ------------------------------------------------------------
start_webui() {
  if kai_http_ok "$(kai_webui_url)/health" 3 || kai_port_busy "$KAI_WEBUI_PORT"; then
    ok "Open WebUI déjà en service sur $(kai_webui_url)"
    return 0
  fi

  local bin="$KAI_ROOT/.venv/bin/open-webui"
  # On lance l'exécutable du venv, jamais `uvx ...@latest` : au moment du vol,
  # une commande qui résout une version en ligne échouerait (§5).
  [ -x "$bin" ] || die "Open WebUI absent de .venv. Lancez 'make install'."

  info "Démarrage d'Open WebUI…"
  OLLAMA_BASE_URL="$(kai_ollama_url)" \
  HF_HUB_OFFLINE="${HF_HUB_OFFLINE:-1}" \
  TRANSFORMERS_OFFLINE="${TRANSFORMERS_OFFLINE:-1}" \
  ANONYMIZED_TELEMETRY="${ANONYMIZED_TELEMETRY:-false}" \
  DO_NOT_TRACK="${DO_NOT_TRACK:-true}" \
  SCARF_NO_ANALYTICS="${SCARF_NO_ANALYTICS:-true}" \
  WEBUI_AUTH="${WEBUI_AUTH:-true}" \
  RAG_EMBEDDING_ENGINE="${RAG_EMBEDDING_ENGINE:-ollama}" \
  RAG_EMBEDDING_MODEL="$KAI_MODEL_EMBEDDING" \
  DATA_DIR="$KAI_ROOT/data/webui" \
    nohup "$bin" serve --host "$KAI_BIND_HOST" --port "$KAI_WEBUI_PORT" \
      >> "$LOG_DIR/webui.log" 2>&1 &
  printf '%s' "$!" > "$KAI_RUN_DIR/webui.pid"

  info "Premier démarrage : la préparation de la base peut prendre une minute."
  local i=0
  while [ "$i" -lt 90 ]; do
    if kai_http_ok "$(kai_webui_url)/health" 2; then
      ok "Open WebUI en service sur $(kai_webui_url)"
      return 0
    fi
    i=$((i + 1))
    sleep 1
  done
  err "Open WebUI n'a pas répondu en 90 s. Voir $LOG_DIR/webui.log"
  return 1
}

title "Démarrage de KAI (V0)"
start_ollama || exit 1

if [ "$ONLY_OLLAMA" = "1" ]; then
  ok "Ollama seul démarré, comme demandé."
  exit 0
fi

start_webui || exit 1

log ""
ok "KAI est prêt.  Ouvrez : $(kai_webui_url)"
log ""
log "  Modèle principal : $KAI_MODEL_PRIMARY"
log "  Modèle de secours : $KAI_MODEL_FALLBACK  (à choisir si la mémoire sature)"
log "  Contexte : $KAI_NUM_CTX tokens"
log ""
info "Arrêt : make stop   ·   État : make status"
