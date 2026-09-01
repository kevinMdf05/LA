#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Diagnostic complet, utilisable hors ligne.
#
# Le rapport produit ne contient NI secret, NI contenu de document (§2.2) :
# il doit pouvoir être relu, copié ou partagé sans crainte.
# ---------------------------------------------------------------------------

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

kai_load_env
kai_mkdirs
REPORT="$KAI_REPORT_DIR/diagnose-$(kai_timestamp).md"

title "Diagnostic KAI"

{
  printf '# Diagnostic KAI\n\n'
  printf 'Généré le %s\n\n' "$(kai_iso_date)"
  printf 'Ce rapport ne contient ni clé, ni contenu de document.\n\n'

  printf '## Système\n\n```\n'
  uname -a
  is_macos && sw_vers 2>/dev/null
  printf '```\n\n'

  printf '## Ressources\n\n```\n'
  if is_macos; then
    printf 'Mémoire totale : '; sysctl -n hw.memsize 2>/dev/null \
      | awk '{printf "%.1f Go\n", $1/1073741824}'
    memory_pressure 2>/dev/null | tail -3
    sysctl -n vm.swapusage 2>/dev/null
    pmset -g batt 2>/dev/null | head -2
  else
    have free && free -h
  fi
  df -h "$HOME" 2>/dev/null
  printf '```\n\n'

  printf '## Outils\n\n```\n'
  for t in ollama uv python3 git curl docker; do
    if have "$t"; then
      printf '%-8s %s\n' "$t" "$("$t" --version 2>&1 | head -1)"
    else
      printf '%-8s absent\n' "$t"
    fi
  done
  printf '```\n\n'

  printf '## Services\n\n```\n'
  if kai_http_ok "$(kai_ollama_url)/api/tags" 3; then
    printf 'Ollama      EN SERVICE  %s\n' "$(kai_ollama_url)"
  else
    printf 'Ollama      ARRETE\n'
  fi
  if kai_http_ok "$(kai_webui_url)/health" 3; then
    printf 'Open WebUI  EN SERVICE  %s\n' "$(kai_webui_url)"
  else
    printf 'Open WebUI  ARRETE\n'
  fi
  printf '```\n\n'

  printf '## Modèles\n\n```\n'
  if have ollama; then ollama list 2>&1; else printf 'ollama absent\n'; fi
  printf '```\n\n'

  printf '### Modèles chargés en mémoire\n\n```\n'
  if have ollama; then ollama ps 2>&1; fi
  printf '```\n\n'

  printf '## Réseau en écoute\n\n```\n'
  if have lsof; then
    lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null \
      | grep -E "(COMMAND|:$KAI_WEBUI_PORT |:$KAI_OLLAMA_PORT )" || printf 'aucun\n'
  elif have ss; then
    ss -ltn 2>/dev/null | grep -E ":($KAI_WEBUI_PORT|$KAI_OLLAMA_PORT)\b" || printf 'aucun\n'
  fi
  printf '```\n\n'

  printf '## Configuration\n\n'
  printf 'Variables non sensibles uniquement — les clés sont volontairement omises.\n\n```\n'
  printf 'KAI_BIND_HOST        %s\n' "$KAI_BIND_HOST"
  printf 'KAI_WEBUI_PORT       %s\n' "$KAI_WEBUI_PORT"
  printf 'KAI_MODEL_PRIMARY    %s\n' "$KAI_MODEL_PRIMARY"
  printf 'KAI_MODEL_FALLBACK   %s\n' "$KAI_MODEL_FALLBACK"
  printf 'KAI_MODEL_EMBEDDING  %s\n' "$KAI_MODEL_EMBEDDING"
  printf 'KAI_NUM_CTX          %s\n' "$KAI_NUM_CTX"
  printf 'HF_HUB_OFFLINE       %s\n' "${HF_HUB_OFFLINE:-non défini}"
  printf 'TRANSFORMERS_OFFLINE %s\n' "${TRANSFORMERS_OFFLINE:-non défini}"
  # On indique la PRÉSENCE d'une clé, jamais sa valeur (§9.1).
  for k in OPENAI_API_KEY ANTHROPIC_API_KEY GOOGLE_API_KEY; do
    v="$(eval "printf '%s' \"\${$k:-}\"")"
    if [ -n "$v" ]; then printf '%-20s [définie, valeur masquée]\n' "$k"
    else printf '%-20s [non définie]\n' "$k"; fi
  done
  printf '```\n\n'

  printf '## Fin des journaux\n\n'
  for l in ollama webui; do
    if [ -f "$KAI_ROOT/logs/$l.log" ]; then
      printf '### %s.log (30 dernières lignes)\n\n```\n' "$l"
      tail -30 "$KAI_ROOT/logs/$l.log" 2>/dev/null
      printf '```\n\n'
    fi
  done
} > "$REPORT"

# --- Contrôle : le rapport ne doit contenir aucun secret -------------------
if grep -qE 'sk-[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{35}' "$REPORT" 2>/dev/null; then
  rm -f "$REPORT"
  die "ANOMALIE : un secret a fuité dans le rapport. Rapport supprimé."
fi

ok "Rapport écrit : $REPORT"
ok "Vérifié : aucun secret dans le rapport."
log ""
info "Affichez-le :  cat $REPORT"
