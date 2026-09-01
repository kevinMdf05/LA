#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Arrête proprement les services KAI démarrés par scripts/start.sh.
#
# N'arrête que ce que KAI a lancé (fichiers .run/*.pid).  Si Kevin a lancé
# l'application Ollama à la main, elle n'est pas touchée : ce script ne tue
# pas des processus qu'il n'a pas démarrés.
# ---------------------------------------------------------------------------

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

kai_load_env
kai_mkdirs
title "Arrêt de KAI"

stop_one() {
  local name="$1" pidfile="$KAI_RUN_DIR/$2.pid"
  if [ ! -f "$pidfile" ]; then
    info "$name : aucun processus lancé par KAI."
    return 0
  fi
  local pid; pid="$(cat "$pidfile" 2>/dev/null || true)"
  if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
    info "$name : déjà arrêté."
    rm -f "$pidfile"
    return 0
  fi

  info "Arrêt de $name (pid $pid)…"
  kill "$pid" 2>/dev/null || true
  local i=0
  while [ "$i" -lt 15 ]; do
    kill -0 "$pid" 2>/dev/null || { ok "$name arrêté."; rm -f "$pidfile"; return 0; }
    i=$((i + 1)); sleep 1
  done

  warn "$name ne répond pas — arrêt forcé."
  kill -9 "$pid" 2>/dev/null || true
  rm -f "$pidfile"
  ok "$name arrêté (forcé)."
}

stop_one "Open WebUI" webui
stop_one "Ollama" ollama

log ""
if kai_port_busy "$KAI_WEBUI_PORT"; then
  warn "Le port $KAI_WEBUI_PORT reste occupé par un processus que KAI n'a pas lancé."
fi
if kai_port_busy "$KAI_OLLAMA_PORT"; then
  warn "Le port $KAI_OLLAMA_PORT reste occupé — probablement l'application Ollama,"
  warn "lancée hors de KAI. Quittez-la depuis la barre de menus si nécessaire."
fi
ok "Terminé."
