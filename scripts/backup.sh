#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# KAI-EXEC-006 — Sauvegarde des données persistantes.
#
#   scripts/backup.sh              archive claire
#   ENCRYPT=1 scripts/backup.sh    archive chiffrée (GPG symétrique)
#
# .env est DÉLIBÉRÉMENT EXCLU : une sauvegarde ne transporte pas les secrets
# (§9.1, KAI-EXEC-006).  Conséquence à connaître : restaurer ne restaure pas
# les clés — elles se reconfigurent depuis le trousseau.
# ---------------------------------------------------------------------------

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

kai_load_env
title "Sauvegarde KAI"

STAMP="$(kai_timestamp)"
mkdir -p "$KAI_BACKUP_DIR"
ARCHIVE="$KAI_BACKUP_DIR/kai-backup-$STAMP.tar.gz"

# --- Ce qui est sauvegardé -------------------------------------------------
# Les modèles ne le sont pas : 5,64 Go re-téléchargeables, ce serait doubler
# l'espace disque pour rien (§15).  Les documents sources et l'index le sont.
SOURCES=""
[ -d "$KAI_ROOT/data" ]    && SOURCES="$SOURCES data"
[ -d "$KAI_ROOT/reports" ] && SOURCES="$SOURCES reports"
[ -f "$KAI_ROOT/infra/requirements.lock" ] && SOURCES="$SOURCES infra/requirements.lock"

if [ -z "$SOURCES" ]; then
  die "Rien à sauvegarder : ni data/, ni reports/. Avez-vous déjà lancé KAI ?"
fi

log ""
log "  Inclus  : $SOURCES"
log "  Exclus  : .env (secrets), .venv, models/, logs/"
log ""

# --- Archive ---------------------------------------------------------------
info "Création de l'archive…"
# shellcheck disable=SC2086
tar -czf "$ARCHIVE" \
  --exclude='.env' \
  --exclude='*.log' \
  --exclude='__pycache__' \
  --exclude='.DS_Store' \
  -C "$KAI_ROOT" $SOURCES

SIZE="$(du -h "$ARCHIVE" | awk '{print $1}')"
ok "Archive créée : $ARCHIVE ($SIZE)"

# --- Filet de sécurité : jamais de secret dans une archive -----------------
# On vérifie plutôt que de faire confiance à --exclude.
if tar -tzf "$ARCHIVE" | grep -qE '(^|/)\.env$'; then
  rm -f "$ARCHIVE"
  die "ANOMALIE : .env s'est retrouvé dans l'archive. Archive supprimée."
fi
ok "Vérifié : aucun fichier .env dans l'archive."

# --- Empreinte -------------------------------------------------------------
# Une sauvegarde sans checksum ne permet pas de distinguer une archive
# intacte d'une archive tronquée par un disque plein.
CHECKSUM_FILE="$ARCHIVE.sha256"
if have shasum; then
  ( cd "$KAI_BACKUP_DIR" && shasum -a 256 "$(basename "$ARCHIVE")" > "$(basename "$CHECKSUM_FILE")" )
elif have sha256sum; then
  ( cd "$KAI_BACKUP_DIR" && sha256sum "$(basename "$ARCHIVE")" > "$(basename "$CHECKSUM_FILE")" )
else
  warn "Ni shasum ni sha256sum — empreinte non calculée."
fi
[ -f "$CHECKSUM_FILE" ] && ok "Empreinte : $CHECKSUM_FILE"

# --- Chiffrement facultatif ------------------------------------------------
if [ "${ENCRYPT:-0}" = "1" ]; then
  if ! have gpg; then
    warn "gpg absent — archive laissée en clair."
    warn "Installez gnupg, ou stockez l'archive sur un volume chiffré."
  else
    info "Chiffrement (la phrase de passe est demandée, jamais stockée)…"
    gpg --symmetric --cipher-algo AES256 --output "$ARCHIVE.gpg" "$ARCHIVE"
    rm -f "$ARCHIVE"
    ok "Archive chiffrée : $ARCHIVE.gpg (version claire supprimée)"
    ARCHIVE="$ARCHIVE.gpg"
  fi
fi

log ""
ok "Sauvegarde terminée."
log ""
warn "Une sauvegarde n'a de valeur que restaurée (R-010)."
info "Testez-la maintenant :  make restore ARCHIVE=$ARCHIVE"
