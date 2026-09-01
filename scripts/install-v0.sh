#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# KAI-EXEC-002 — Installation de la V0 (Ollama natif + Open WebUI épinglé).
#
# Ce script n'installe PAS Ollama à votre place : installer une application
# système est une décision de Kevin, pas d'un script.  Il vérifie, il guide,
# et il installe uniquement ce qui vit dans le dossier du projet (le venv).
#
# Aucun téléchargement de modèle ici — c'est `make preload`, séparé exprès
# pour que Kevin voie la taille avant de la télécharger (§19).
# ---------------------------------------------------------------------------

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

OPEN_WEBUI_VERSION="0.11.3"   # épinglé — voir VERSIONS.md
VENV_DIR="$KAI_ROOT/.venv"
LOCKFILE="$KAI_ROOT/infra/requirements.lock"

kai_load_env
title "KAI-EXEC-002 — Installation de la V0"

# --- 1. Plateforme ---------------------------------------------------------
if ! is_macos; then
  warn "Système détecté : $(uname -s).  La V0 est conçue pour macOS."
  warn "L'installation va continuer, mais elle n'est ni testée ni supportée ici."
fi

# --- 2. Ollama -------------------------------------------------------------
if have ollama; then
  ok "Ollama présent : $(ollama --version 2>&1 | head -1)"
else
  err "Ollama est absent."
  log ""
  log "  Installez-le, puis relancez ce script :"
  log ""
  log "    • Application officielle : https://ollama.com/download/mac"
  log "    • ou, si Homebrew est installé :  brew install --cask ollama"
  log ""
  log "  Documentation : https://docs.ollama.com/macos"
  log ""
  die "Installation interrompue — Ollama requis."
fi

# --- 3. uv -----------------------------------------------------------------
if have uv; then
  ok "uv présent : $(uv --version 2>&1 | head -1)"
else
  err "uv est absent."
  log ""
  log "  Installez-le, puis relancez :"
  log ""
  log "    curl -LsSf https://astral.sh/uv/install.sh | sh"
  log ""
  log "  Documentation : https://docs.astral.sh/uv/"
  log ""
  die "Installation interrompue — uv requis."
fi

# --- 4. Environnement Python dédié -----------------------------------------
# open-webui 0.11.3 exige Python >= 3.11 et < 3.13 (VERSIONS.md).
info "Création de l'environnement Python (.venv, Python 3.12)…"
uv venv --python 3.12 "$VENV_DIR"
ok "Environnement créé : $VENV_DIR"

info "Installation de open-webui==$OPEN_WEBUI_VERSION (version épinglée)…"
info "Cette étape télécharge plusieurs centaines de Mo. Patientez."
VIRTUAL_ENV="$VENV_DIR" uv pip install --python "$VENV_DIR/bin/python" \
  "open-webui==$OPEN_WEBUI_VERSION"
ok "open-webui $OPEN_WEBUI_VERSION installé."

# --- 5. Verrouillage complet des dépendances (R-006) -----------------------
# Épingler `open-webui` seul ne suffit pas : ce sont ses dépendances
# transitives qui bougent.  Ce lockfile est ce qui permet de réassembler un
# environnement identique, y compris hors ligne.
mkdir -p "$(dirname "$LOCKFILE")"
{
  printf '# KAI — dépendances Python verrouillées\n'
  printf '# Généré le %s par scripts/install-v0.sh\n' "$(kai_iso_date)"
  printf '# open-webui épinglé à %s (voir VERSIONS.md)\n' "$OPEN_WEBUI_VERSION"
  printf '# NE PAS ÉDITER À LA MAIN — régénérer via `make install`.\n\n'
  VIRTUAL_ENV="$VENV_DIR" uv pip freeze --python "$VENV_DIR/bin/python"
} > "$LOCKFILE"
ok "Dépendances verrouillées : $LOCKFILE ($(grep -vc '^#' "$LOCKFILE") paquets)"

# --- 6. Fichier .env -------------------------------------------------------
ENVFILE="$KAI_ROOT/.env"
if [ ! -f "$ENVFILE" ]; then
  cp "$KAI_ROOT/.env.example" "$ENVFILE"
  ok ".env créé depuis .env.example"
else
  info ".env existe déjà — laissé intact (aucune écrasure de configuration)."
fi
chmod 600 "$ENVFILE"
ok "Permissions de .env : 600 (lisible par vous seul)"

# --- 7. Clé de session Open WebUI ------------------------------------------
# Générée localement, jamais affichée, jamais committée (.env est ignoré).
if grep -q '^WEBUI_SECRET_KEY=$' "$ENVFILE" 2>/dev/null; then
  if have openssl; then
    SECRET="$(openssl rand -hex 32)"
  else
    SECRET="$(python3 -c 'import secrets; print(secrets.token_hex(32))')"
  fi
  # Édition en place, compatible sed macOS (BSD) et GNU.
  tmp="$(mktemp)"
  sed "s|^WEBUI_SECRET_KEY=$|WEBUI_SECRET_KEY=$SECRET|" "$ENVFILE" > "$tmp"
  mv "$tmp" "$ENVFILE"
  chmod 600 "$ENVFILE"
  unset SECRET
  ok "Clé de session générée et écrite dans .env (non affichée, non committée)."
else
  info "Clé de session déjà présente — conservée."
fi

# --- 8. Résumé -------------------------------------------------------------
title "Installation terminée"
log ""
log "  Installé          open-webui $OPEN_WEBUI_VERSION dans .venv"
log "  Verrouillé        infra/requirements.lock"
log "  Configuration     .env (permissions 600)"
log ""
log "  Aucun modèle n'a encore été téléchargé."
log ""
info "Étape suivante : 'make preload' — téléchargera ≈ 5,64 Go."
info "Vérifiez d'abord l'espace libre dans reports/hardware-report.md (Q-001)."
