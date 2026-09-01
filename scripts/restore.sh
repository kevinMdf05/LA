#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# KAI-EXEC-006 — Restauration d'une sauvegarde.
#
#   scripts/restore.sh <archive>              → dossier temporaire (défaut)
#   scripts/restore.sh <archive> --in-place   → écrase les données vivantes
#
# Par défaut la restauration va dans un dossier TEMPORAIRE, jamais par-dessus
# les données en service.  C'est ce qui permet de tester une sauvegarde sans
# risquer de détruire ce qui marche (R-010).
# ---------------------------------------------------------------------------

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

kai_load_env
title "Restauration KAI"

ARCHIVE="${1:-}"
IN_PLACE=0
[ "${2:-}" = "--in-place" ] && IN_PLACE=1

if [ -z "$ARCHIVE" ]; then
  err "Usage : scripts/restore.sh <archive> [--in-place]"
  log ""
  log "  Sauvegardes disponibles :"
  ls -1t "$KAI_BACKUP_DIR"/kai-backup-*.tar.gz* 2>/dev/null | sed 's/^/    /' \
    || log "    (aucune)"
  exit 1
fi
[ -f "$ARCHIVE" ] || die "Archive introuvable : $ARCHIVE"

# --- Vérification de l'empreinte avant toute extraction --------------------
CHECKSUM_FILE="$ARCHIVE.sha256"
if [ -f "$CHECKSUM_FILE" ]; then
  info "Vérification de l'empreinte…"
  if ( cd "$(dirname "$ARCHIVE")" && \
       { have shasum && shasum -a 256 -c "$(basename "$CHECKSUM_FILE")"; } \
       >/dev/null 2>&1 ); then
    ok "Empreinte conforme — l'archive est intacte."
  else
    err "EMPREINTE NON CONFORME : l'archive est corrompue ou modifiée."
    die "Restauration refusée."
  fi
else
  warn "Pas de fichier .sha256 — intégrité non vérifiable."
fi

# --- Déchiffrement si nécessaire -------------------------------------------
WORK_ARCHIVE="$ARCHIVE"
TMP_PLAIN=""
case "$ARCHIVE" in
  *.gpg)
    have gpg || die "Archive chiffrée mais gpg est absent."
    TMP_PLAIN="$(mktemp -t kai-restore.XXXXXX).tar.gz"
    info "Déchiffrement…"
    gpg --quiet --decrypt --output "$TMP_PLAIN" "$ARCHIVE" \
      || die "Déchiffrement échoué."
    WORK_ARCHIVE="$TMP_PLAIN"
    ok "Archive déchiffrée."
    ;;
esac
cleanup() { [ -n "$TMP_PLAIN" ] && rm -f "$TMP_PLAIN"; }
trap cleanup EXIT

# --- Destination -----------------------------------------------------------
if [ "$IN_PLACE" = "1" ]; then
  warn "MODE --in-place : les données actuelles de $KAI_ROOT/data seront ÉCRASÉES."
  warn "Cette opération n'est pas annulable."
  if [ "${KAI_ASSUME_YES:-0}" != "1" ]; then
    printf '  Taper exactement ECRASER pour confirmer : '
    read -r confirm || confirm=""
    [ "$confirm" = "ECRASER" ] || { info "Annulé. Rien n'a été modifié."; exit 0; }
  fi
  DEST="$KAI_ROOT"
  info "Arrêt des services avant restauration…"
  "$KAI_ROOT/scripts/stop.sh" >/dev/null 2>&1 || true
else
  DEST="$(mktemp -d -t kai-restore-test.XXXXXX)"
  info "Restauration vers un dossier temporaire (aucune donnée vivante touchée)."
fi

# --- Extraction ------------------------------------------------------------
info "Extraction…"
tar -xzf "$WORK_ARCHIVE" -C "$DEST"
ok "Extraction terminée."

# --- Contrôle du contenu restauré ------------------------------------------
title "Contenu restauré"
log ""
find "$DEST" -maxdepth 2 -mindepth 1 -not -path '*/.*' 2>/dev/null \
  | head -20 | sed "s|$DEST|  .|"
FILES="$(find "$DEST" -type f 2>/dev/null | wc -l | tr -d ' ')"
log ""
ok "$FILES fichiers restaurés."

if [ "$IN_PLACE" = "1" ]; then
  log ""
  ok "Restauration en place terminée."
  warn "Les clés API ne sont PAS restaurées (elles ne sont jamais sauvegardées)."
  info "Reconfigurez .env si nécessaire, puis : make start"
else
  log ""
  ok "Test de restauration réussi — la sauvegarde est exploitable (R-010)."
  log ""
  log "  Emplacement : $DEST"
  log ""
  info "Inspectez-le, puis supprimez-le :  rm -rf $DEST"
  info "Pour restaurer réellement :  make restore ARCHIVE=$ARCHIVE IN_PLACE=1"
fi
