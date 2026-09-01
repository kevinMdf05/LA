#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# KAI-EXEC-002 / KAI-EXEC-004 — Téléchargement des modèles épinglés.
#
# Point critique du projet (R-002) : tout ce qui sera nécessaire en vol doit
# être sur le disque AVANT le départ.  Un modèle d'embeddings manquant casse
# le RAG hors ligne sans message clair.
#
# Ce script annonce la taille AVANT de télécharger et demande confirmation,
# comme l'exige le §19 ("présente à Kevin les téléchargements prévus, leur
# taille et l'espace libre restant").
# ---------------------------------------------------------------------------

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

kai_load_env
kai_mkdirs
title "Préchargement des modèles locaux"

have ollama || die "Ollama absent. Lancez d'abord 'make install'."

# Tailles annoncées par la bibliothèque Ollama, vérifiées le 2026-09-01
# (voir VERSIONS.md).  Bash 3.2 : pas de tableau associatif, on utilise des
# lignes "tag|taille|rôle".
MODELS="
$KAI_MODEL_PRIMARY|3.4|LLM principal
$KAI_MODEL_FALLBACK|1.9|LLM de secours (obligatoire)
$KAI_MODEL_EMBEDDING|0.34|Embeddings (indispensable au RAG hors ligne)
"

# --- 1. Annonce ------------------------------------------------------------
log ""
log "  Modèles à télécharger :"
log ""
TOTAL=0
printf '%s\n' "$MODELS" | while IFS='|' read -r tag size role; do
  [ -n "$tag" ] || continue
  printf '    %-34s %6s Go   %s\n' "$tag" "$size" "$role"
done
TOTAL="$(printf '%s\n' "$MODELS" | awk -F'|' 'NF>1 {s+=$2} END{printf "%.2f", s}')"
log ""
log "  Total : ${TOTAL} Go"

# --- 2. Espace libre -------------------------------------------------------
FREE_GB="$(df -k "$HOME" 2>/dev/null | awk 'NR==2 {printf "%.1f", $4/1048576}')"
if [ -n "$FREE_GB" ]; then
  AFTER="$(awk -v f="$FREE_GB" -v t="$TOTAL" 'BEGIN{printf "%.1f", f-t}')"
  log "  Espace libre actuel : ${FREE_GB} Go  →  après téléchargement : ${AFTER} Go"
  log ""
  VERDICT="$(awk -v a="$AFTER" 'BEGIN{ if (a >= 15) print "ok"; else if (a >= 5) print "juste"; else print "danger" }')"
  case "$VERDICT" in
    ok)     ok "Marge suffisante après téléchargement (≥ 15 Go)." ;;
    juste)  warn "Marge faible après téléchargement (${AFTER} Go). Le plan en demande 15 à 20 (§15)." ;;
    danger) err "Marge dangereuse après téléchargement (${AFTER} Go)."
            err "Remplir le disque dégrade macOS, le swap et les caches."
            die "Faites du ménage avant de relancer. Aucun téléchargement lancé." ;;
  esac
else
  warn "Espace libre non mesurable — vérifiez manuellement avant de continuer."
fi

# --- 3. Confirmation -------------------------------------------------------
if [ "${KAI_ASSUME_YES:-0}" != "1" ]; then
  log ""
  printf '  Lancer le téléchargement de %s Go ? [o/N] ' "$TOTAL"
  read -r answer || answer=""
  case "$answer" in
    o|O|y|Y|oui|OUI) : ;;
    *) log ""; info "Annulé. Aucun téléchargement effectué."; exit 0 ;;
  esac
fi

# --- 4. Ollama doit tourner -------------------------------------------------
if ! kai_http_ok "$(kai_ollama_url)/api/tags" 3; then
  info "Démarrage du service Ollama…"
  "$KAI_ROOT/scripts/start.sh" --ollama-only
fi

# --- 5. Téléchargement ------------------------------------------------------
FAILED=""
for entry in $(printf '%s\n' "$MODELS" | awk -F'|' 'NF>1 {print $1}'); do
  title "Téléchargement : $entry"
  if ollama pull "$entry"; then
    ok "$entry téléchargé."
  else
    err "Échec du téléchargement de $entry"
    FAILED="$FAILED $entry"
  fi
done

# --- 6. Inventaire réel (livrable §18 n°6) ---------------------------------
INVENTORY="$KAI_REPORT_DIR/models-installed.md"
{
  printf '# Modèles réellement installés\n\n'
  printf 'Relevé le %s par `scripts/preload-models.sh`.\n\n' "$(kai_iso_date)"
  printf 'Sortie brute de `ollama list` — c est la taille sur disque qui fait foi,\n'
  printf 'pas la taille annoncée par la bibliothèque.\n\n'
  printf '```\n'
  ollama list 2>&1
  printf '```\n\n'
  printf '## Rôles attendus\n\n'
  printf '| Rôle | Tag épinglé |\n|---|---|\n'
  printf '| LLM principal | `%s` |\n' "$KAI_MODEL_PRIMARY"
  printf '| LLM de secours | `%s` |\n' "$KAI_MODEL_FALLBACK"
  printf '| Embeddings | `%s` |\n' "$KAI_MODEL_EMBEDDING"
  printf '\nEspace libre restant : %s Go\n' \
    "$(df -k "$HOME" 2>/dev/null | awk 'NR==2 {printf "%.1f", $4/1048576}')"
} > "$INVENTORY"
ok "Inventaire écrit : $INVENTORY"

# --- 7. Vérification : les trois modèles sont-ils là ? ---------------------
title "Vérification"
MISSING=""
for entry in $(printf '%s\n' "$MODELS" | awk -F'|' 'NF>1 {print $1}'); do
  if ollama list 2>/dev/null | awk '{print $1}' | grep -qx "$entry"; then
    ok "présent : $entry"
  else
    err "ABSENT : $entry"
    MISSING="$MISSING $entry"
  fi
done

log ""
if [ -n "$MISSING" ]; then
  err "Modèles manquants :$MISSING"
  err "Le RAG ou le chat ne fonctionneront pas hors ligne (R-002)."
  die "Relancez 'make preload' avec une connexion stable."
fi

ok "Les trois modèles épinglés sont sur le disque."
info "Étape suivante : 'make start', puis 'make offline-test' avant le vol."
