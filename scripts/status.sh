#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# État de KAI : services, modèles, mémoire, disque, et surtout — quelles
# interfaces réseau sont RÉELLEMENT en écoute (contrôle de sécurité §14).
# ---------------------------------------------------------------------------

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

kai_load_env
title "État de KAI"

# --- Services --------------------------------------------------------------
log ""
if kai_http_ok "$(kai_ollama_url)/api/tags" 3; then
  ok "Ollama       en service — $(kai_ollama_url)"
else
  err "Ollama       arrêté"
fi

if kai_http_ok "$(kai_webui_url)/health" 3; then
  ok "Open WebUI   en service — $(kai_webui_url)"
else
  err "Open WebUI   arrêté"
fi

# --- Modèles ---------------------------------------------------------------
title "Modèles"
if have ollama && kai_http_ok "$(kai_ollama_url)/api/tags" 3; then
  for role_tag in "principal:$KAI_MODEL_PRIMARY" "secours:$KAI_MODEL_FALLBACK" "embeddings:$KAI_MODEL_EMBEDDING"; do
    role="${role_tag%%:*}"
    tag="${role_tag#*:}"
    if ollama list 2>/dev/null | awk '{print $1}' | grep -qx "$tag"; then
      ok "$(printf '%-11s' "$role") $tag"
    else
      err "$(printf '%-11s' "$role") $tag — ABSENT (bloquant hors ligne, R-002)"
    fi
  done
  # Modèle actuellement chargé en mémoire, s'il y en a un.
  loaded="$(ollama ps 2>/dev/null | awk 'NR>1 {print $1}' | tr '\n' ' ')"
  log ""
  if [ -n "$(printf '%s' "$loaded" | tr -d ' ')" ]; then
    info "Chargé en mémoire : $loaded"
  else
    info "Aucun modèle chargé en mémoire (la RAM est rendue à macOS)."
  fi
else
  warn "Ollama injoignable — impossible de lister les modèles."
fi

# --- Réseau : le contrôle qui compte ---------------------------------------
title "Interfaces en écoute"
log ""
log "  Toute ligne montrant 0.0.0.0 ou * est une anomalie de sécurité (§9.2)."
log ""
listeners=""
if have lsof; then
  listeners="$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null \
    | awk -v a="$KAI_WEBUI_PORT" -v b="$KAI_OLLAMA_PORT" \
      'NR==1 || $0 ~ ":"a" " || $0 ~ ":"b" "')"
elif have ss; then
  listeners="$(ss -ltnp 2>/dev/null | grep -E ":($KAI_WEBUI_PORT|$KAI_OLLAMA_PORT)\b" || true)"
fi

if [ -n "$listeners" ]; then
  printf '%s\n' "$listeners" | sed 's/^/    /'
  if printf '%s' "$listeners" | grep -qE '(0\.0\.0\.0|\*):('"$KAI_WEBUI_PORT"'|'"$KAI_OLLAMA_PORT"')'; then
    log ""
    err "ANOMALIE : un service KAI écoute au-delà de la boucle locale."
    err "Arrêtez-le (make stop), vérifiez KAI_BIND_HOST dans .env, voir SECURITY.md."
  else
    log ""
    ok "Aucun service KAI exposé hors de 127.0.0.1."
  fi
else
  info "Aucun service KAI en écoute (ni lsof ni ss n'a rien trouvé)."
fi

# --- Ressources ------------------------------------------------------------
title "Ressources"
log ""
if is_macos; then
  free_pct="$(memory_pressure 2>/dev/null \
    | awk -F': *' '/free percentage/ {gsub(/%/,"",$2); print $2}' | tail -1)"
  swap="$(sysctl -n vm.swapusage 2>/dev/null | sed -n 's/.*used = \([^ ]*\).*/\1/p')"
  [ -n "$free_pct" ] && log "  Mémoire libre .... ${free_pct} %"
  [ -n "$swap" ]     && log "  Swap utilisé ..... $swap"
  # Le swap est le signal qui compte sur 8 Go : dès qu'il grimpe, tout rame.
  if [ -n "$swap" ] && printf '%s' "$swap" | grep -qE '^[0-9.]+[MG]'; then
    swap_mb="$(printf '%s' "$swap" | sed 's/M$//; s/G$/000/' )"
    if awk -v s="$swap_mb" 'BEGIN{exit !(s > 1000)}' 2>/dev/null; then
      warn "Swap élevé — passez au modèle de secours $KAI_MODEL_FALLBACK (OFFLINE_RUNBOOK §C)."
    fi
  fi
else
  have free && free -h | sed 's/^/  /'
fi
df -h "$HOME" 2>/dev/null | awk 'NR==2 {printf "  Disque libre ..... %s sur %s\n", $4, $2}'

log ""
info "Diagnostic complet : make diagnose"
