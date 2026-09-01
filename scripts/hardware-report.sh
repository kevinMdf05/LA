#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# KAI-EXEC-001 — Audit matériel et environnement.
#
# STRICTEMENT NON DESTRUCTIF : ce script lit, il n'installe rien, ne modifie
# aucun réglage système et n'écrit que dans reports/.
#
# Produit :
#   reports/hardware-report.json  — données brutes, comparables aux commandes
#   reports/hardware-report.md    — résumé lisible pour Kevin
#
# Hors macOS, le rapport porte "status": "degraded" : les valeurs Darwin ne
# sont pas disponibles et AUCUNE valeur n'est inventée pour combler le vide.
# ---------------------------------------------------------------------------

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

kai_mkdirs
JSON_OUT="$KAI_REPORT_DIR/hardware-report.json"
MD_OUT="$KAI_REPORT_DIR/hardware-report.md"

OS="$(kai_os)"
STATUS="complete"
[ "$OS" = "macos" ] || STATUS="degraded"

title "KAI-EXEC-001 — Audit matériel (lecture seule)"

# --- Valeurs par défaut : "unknown" tant qu'on n'a pas mesuré --------------
OS_NAME="$(uname -s)"; OS_VERSION="unknown"; OS_BUILD="unknown"
ARCH="$(uname -m)"; CPU_BRAND="unknown"; CPU_CORES="unknown"
MEM_BYTES=0; MEM_GB="unknown"; MEM_FREE_PCT="unknown"
DISK_FREE_KB=0; DISK_FREE_GB="unknown"; DISK_TOTAL_GB="unknown"
BATTERY="unknown"; SWAP_USED="unknown"

if [ "$OS" = "macos" ]; then
  OS_VERSION="$(sw_vers -productVersion 2>/dev/null || echo unknown)"
  OS_BUILD="$(sw_vers -buildVersion 2>/dev/null || echo unknown)"
  CPU_BRAND="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo unknown)"
  CPU_CORES="$(sysctl -n hw.ncpu 2>/dev/null || echo unknown)"
  MEM_BYTES="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
  # Pression mémoire au repos : dernière ligne de `memory_pressure`.
  if have memory_pressure; then
    MEM_FREE_PCT="$(memory_pressure 2>/dev/null \
      | awk -F': *' '/free percentage/ {gsub(/%/,"",$2); print $2}' | tail -1)"
    [ -n "$MEM_FREE_PCT" ] || MEM_FREE_PCT="unknown"
  fi
  if have sysctl; then
    SWAP_USED="$(sysctl -n vm.swapusage 2>/dev/null \
      | sed -n 's/.*used = \([^ ]*\).*/\1/p')"
    [ -n "$SWAP_USED" ] || SWAP_USED="unknown"
  fi
  if have pmset; then
    BATTERY="$(pmset -g batt 2>/dev/null | sed -n '2s/.*[[:space:]]\([0-9]*%\).*/\1/p')"
    [ -n "$BATTERY" ] || BATTERY="unknown"
  fi
elif [ "$OS" = "linux" ]; then
  OS_VERSION="$(uname -r)"
  CPU_BRAND="$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo 2>/dev/null || echo unknown)"
  CPU_CORES="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo unknown)"
  MEM_BYTES="$(awk '/MemTotal/ {print $2*1024; exit}' /proc/meminfo 2>/dev/null || echo 0)"
fi

# --- Mémoire et disque ------------------------------------------------------
# Le disque mesuré est celui qui porte $HOME : c'est là qu'Ollama range les
# poids (~/.ollama), donc c'est le seul espace libre qui compte ici.
if [ "$MEM_BYTES" -gt 0 ] 2>/dev/null; then
  MEM_GB="$(awk -v b="$MEM_BYTES" 'BEGIN{printf "%.1f", b/1073741824}')"
fi
DISK_LINE="$(df -k "$HOME" 2>/dev/null | awk 'NR==2 {print $2, $4}')"
if [ -n "$DISK_LINE" ]; then
  DISK_TOTAL_KB="$(printf '%s' "$DISK_LINE" | awk '{print $1}')"
  DISK_FREE_KB="$(printf '%s' "$DISK_LINE" | awk '{print $2}')"
  DISK_TOTAL_GB="$(awk -v k="$DISK_TOTAL_KB" 'BEGIN{printf "%.1f", k/1048576}')"
  DISK_FREE_GB="$(awk -v k="$DISK_FREE_KB" 'BEGIN{printf "%.1f", k/1048576}')"
fi

# --- Outils installés -------------------------------------------------------
tool_version() {
  local name="$1"; shift
  if have "$name"; then
    "$@" 2>&1 | head -1 | tr -d '\r'
  else
    printf 'absent'
  fi
}
V_OLLAMA="$(tool_version ollama ollama --version)"
V_UV="$(tool_version uv uv --version)"
V_PYTHON="$(tool_version python3 python3 --version)"
V_DOCKER="$(tool_version docker docker --version)"
V_GIT="$(tool_version git git --version)"
V_CURL="$(tool_version curl curl --version)"

# --- Ports que KAI utilisera : libres ou déjà occupés ? --------------------
kai_load_env
PORT_WEBUI_STATE="libre"; kai_port_busy "$KAI_WEBUI_PORT" && PORT_WEBUI_STATE="occupé"
PORT_OLLAMA_STATE="libre"; kai_port_busy "$KAI_OLLAMA_PORT" && PORT_OLLAMA_STATE="occupé"

# --- Détermination du profil (§5) ------------------------------------------
# Le profil dépend de la mémoire, pas d'une préférence.
PROFILE="inconnu"; PROFILE_REASON="mémoire non mesurée"
if [ "$MEM_GB" != "unknown" ]; then
  MEM_INT="$(awk -v g="$MEM_GB" 'BEGIN{printf "%d", g}')"
  if   [ "$MEM_INT" -le 8 ];  then PROFILE="A"; PROFILE_REASON="≤ 8 Go : modèle 4B Q4 maximum, contexte 4K, un seul modèle chargé"
  elif [ "$MEM_INT" -le 16 ]; then PROFILE="B"; PROFILE_REASON="≤ 16 Go : 9B Q4 si stable, sinon 4B ; contexte 16K après mesure"
  elif [ "$MEM_INT" -le 24 ]; then PROFILE="C"; PROFILE_REASON="≤ 24 Go : 9B/12B généraliste, 20B pour le raisonnement"
  else                             PROFILE="D"; PROFILE_REASON="> 24 Go : comparer 20B à 27B, garder un 4B rapide"
  fi
fi

# --- Budget disque (§15) ----------------------------------------------------
# 5,64 Go de modèles épinglés + 15 Go de marge exigée pour swap/caches/macOS.
MODELS_GB="5.64"; MARGIN_GB="15"
DISK_VERDICT="inconnu"
if [ "$DISK_FREE_GB" != "unknown" ]; then
  DISK_VERDICT="$(awk -v f="$DISK_FREE_GB" -v m="$MODELS_GB" -v g="$MARGIN_GB" \
    'BEGIN{ if (f >= m+g) print "suffisant"; else if (f >= m) print "juste"; else print "insuffisant" }')"
fi

# --- Écriture du JSON -------------------------------------------------------
cat > "$JSON_OUT" <<JSON
{
  "mission": "KAI-EXEC-001",
  "generated_at": "$(kai_iso_date)",
  "status": "$STATUS",
  "status_note": "$([ "$STATUS" = "complete" ] && printf 'Mesures macOS complètes.' || printf 'Exécuté hors macOS : les mesures Darwin sont absentes, aucune valeur n a ete inventee.')",
  "os": {
    "kernel": "$(kai_json_escape "$OS_NAME")",
    "product_version": "$(kai_json_escape "$OS_VERSION")",
    "build": "$(kai_json_escape "$OS_BUILD")",
    "arch": "$(kai_json_escape "$ARCH")"
  },
  "cpu": {
    "brand": "$(kai_json_escape "$CPU_BRAND")",
    "cores": "$(kai_json_escape "$CPU_CORES")"
  },
  "memory": {
    "total_bytes": $MEM_BYTES,
    "total_gb": "$MEM_GB",
    "free_percent_at_rest": "$MEM_FREE_PCT",
    "swap_used": "$(kai_json_escape "$SWAP_USED")"
  },
  "disk_home_volume": {
    "total_gb": "$DISK_TOTAL_GB",
    "free_gb": "$DISK_FREE_GB",
    "required_models_gb": $MODELS_GB,
    "required_margin_gb": $MARGIN_GB,
    "verdict": "$DISK_VERDICT"
  },
  "battery": "$(kai_json_escape "$BATTERY")",
  "tools": {
    "ollama": "$(kai_json_escape "$V_OLLAMA")",
    "uv": "$(kai_json_escape "$V_UV")",
    "python3": "$(kai_json_escape "$V_PYTHON")",
    "docker": "$(kai_json_escape "$V_DOCKER")",
    "git": "$(kai_json_escape "$V_GIT")",
    "curl": "$(kai_json_escape "$V_CURL")"
  },
  "ports": {
    "webui_$KAI_WEBUI_PORT": "$PORT_WEBUI_STATE",
    "ollama_$KAI_OLLAMA_PORT": "$PORT_OLLAMA_STATE"
  },
  "profile": {
    "id": "$PROFILE",
    "reason": "$(kai_json_escape "$PROFILE_REASON")",
    "recommended_primary": "$KAI_MODEL_PRIMARY",
    "recommended_fallback": "$KAI_MODEL_FALLBACK",
    "recommended_embedding": "$KAI_MODEL_EMBEDDING",
    "recommended_num_ctx": $KAI_NUM_CTX
  }
}
JSON

# --- Écriture du résumé lisible --------------------------------------------
cat > "$MD_OUT" <<MD
# Rapport matériel — KAI-EXEC-001

Généré le $(kai_iso_date) · statut du rapport : **$STATUS**

| Élément | Valeur |
|---|---|
| Système | $OS_NAME $OS_VERSION ($OS_BUILD) |
| Architecture | $ARCH |
| Processeur | $CPU_BRAND — $CPU_CORES cœurs |
| Mémoire totale | $MEM_GB Go |
| Mémoire libre au repos | $MEM_FREE_PCT % |
| Swap utilisé | $SWAP_USED |
| Disque (volume de \$HOME) | $DISK_FREE_GB Go libres sur $DISK_TOTAL_GB Go |
| Batterie | $BATTERY |
| Port $KAI_WEBUI_PORT (Open WebUI) | $PORT_WEBUI_STATE |
| Port $KAI_OLLAMA_PORT (Ollama) | $PORT_OLLAMA_STATE |

## Outils

| Outil | Version |
|---|---|
| ollama | $V_OLLAMA |
| uv | $V_UV |
| python3 | $V_PYTHON |
| docker | $V_DOCKER |
| git | $V_GIT |

## Profil retenu : **$PROFILE**

$PROFILE_REASON

- Modèle principal : \`$KAI_MODEL_PRIMARY\`
- Modèle de secours : \`$KAI_MODEL_FALLBACK\`
- Embeddings : \`$KAI_MODEL_EMBEDDING\`
- Contexte initial : $KAI_NUM_CTX tokens

## Budget disque

Téléchargement prévu **$MODELS_GB Go**, marge de sécurité exigée **$MARGIN_GB Go**.
Espace libre mesuré : **$DISK_FREE_GB Go** → verdict : **$DISK_VERDICT**.

## Décision attendue de Kevin

Valider que cet espace est réellement mobilisable (question Q-001 de
DECISIONS.md) avant de lancer \`make preload\`.
MD

# --- Sortie terminal --------------------------------------------------------
if [ "$STATUS" = "degraded" ]; then
  warn "Exécuté sur $OS_NAME, pas sur macOS : rapport DÉGRADÉ."
  warn "Les mesures qui comptent (mémoire unifiée, pression mémoire, batterie)"
  warn "doivent être prises sur le Mac de Kevin.  Rien n'a été inventé."
fi

log ""
log "  Système ........ $OS_NAME $OS_VERSION ($ARCH)"
log "  Processeur ..... $CPU_BRAND"
log "  Mémoire ........ $MEM_GB Go"
log "  Disque libre ... $DISK_FREE_GB Go  →  $DISK_VERDICT"
log "  Profil ......... $PROFILE"
log ""

case "$DISK_VERDICT" in
  suffisant)   ok "Espace disque suffisant ($MODELS_GB Go de modèles + $MARGIN_GB Go de marge)." ;;
  juste)       warn "Espace juste : les modèles tiennent, la marge de $MARGIN_GB Go non. Faire du ménage avant 'make preload'." ;;
  insuffisant) err  "Espace insuffisant pour $MODELS_GB Go de modèles. Ne pas lancer 'make preload'." ;;
  *)           warn "Espace disque non mesuré." ;;
esac

ok "Rapport écrit : $JSON_OUT"
ok "Résumé écrit  : $MD_OUT"
log ""
info "Vérification indépendante recommandée (§13) — comparez le JSON aux commandes brutes :"
if [ "$OS" = "macos" ]; then
  log "    sw_vers ; uname -m ; sysctl -n hw.memsize ; df -h \$HOME"
else
  log "    uname -a ; free -h ; df -h \$HOME"
fi
