#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# KAI — fonctions communes à tous les scripts.
#
# Compatibilité : bash 3.2 (version livrée avec macOS).  Pas de tableaux
# associatifs, pas de `mapfile`, pas de `${var^^}` — ces constructions sont
# du bash 4+ et échouent silencieusement ou bruyamment sur un Mac.
# ---------------------------------------------------------------------------

set -euo pipefail

# --- Emplacements -----------------------------------------------------------
KAI_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KAI_ROOT="$(cd "$KAI_LIB_DIR/../.." && pwd)"
export KAI_ROOT
KAI_REPORT_DIR="$KAI_ROOT/reports"
KAI_RUN_DIR="$KAI_ROOT/.run"

# --- Couleurs (désactivées si la sortie n'est pas un terminal) --------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET=$'\033[0m'; C_RED=$'\033[31m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'; C_BOLD=$'\033[1m'
else
  C_RESET=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_BOLD=''
fi

# --- Journalisation ---------------------------------------------------------
# Aucun de ces messages ne doit contenir de secret ni de contenu de document
# (§9.1).  Les scripts qui manipulent des valeurs sensibles les masquent
# AVANT d'appeler ces fonctions.
log()      { printf '%s\n' "$*"; }
info()     { printf '%s→%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()       { printf '%s✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()     { printf '%s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()      { printf '%s✗%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
title()    { printf '\n%s%s%s\n' "$C_BOLD" "$*" "$C_RESET"; }
die()      { err "$*"; exit 1; }

# --- Détection de plateforme ------------------------------------------------
# Les scripts sont écrits pour macOS.  Ils doivent le dire clairement quand
# ils tournent ailleurs, plutôt que de produire des valeurs fausses.
kai_os() {
  case "$(uname -s)" in
    Darwin) printf 'macos' ;;
    Linux)  printf 'linux' ;;
    *)      printf 'unknown' ;;
  esac
}

is_macos() { [ "$(kai_os)" = "macos" ]; }

require_macos() {
  if ! is_macos; then
    die "Ce script doit être exécuté sur le Mac de Kevin (détecté : $(uname -s))."
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

# --- Configuration ----------------------------------------------------------
# Charge .env s'il existe, sinon .env.example pour les valeurs par défaut.
# Ne journalise JAMAIS le contenu chargé.
kai_load_env() {
  local envfile="$KAI_ROOT/.env"
  if [ -f "$envfile" ]; then
    # Avertit si les permissions sont trop ouvertes (§9.1).
    local perms
    perms="$(kai_file_mode "$envfile")"
    if [ -n "$perms" ] && [ "$perms" != "600" ]; then
      warn ".env a les permissions $perms — attendu 600.  Corrigez : chmod 600 .env"
    fi
    set -a
    # shellcheck disable=SC1090
    . "$envfile"
    set +a
  elif [ -f "$KAI_ROOT/.env.example" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$KAI_ROOT/.env.example"
    set +a
  fi
  : "${KAI_BIND_HOST:=127.0.0.1}"
  : "${KAI_WEBUI_PORT:=8080}"
  : "${KAI_OLLAMA_HOST:=127.0.0.1}"
  : "${KAI_OLLAMA_PORT:=11434}"
  : "${KAI_MODEL_PRIMARY:=qwen3.5:4b-q4_K_M}"
  : "${KAI_MODEL_FALLBACK:=qwen3.5:2b-q4_K_M}"
  : "${KAI_MODEL_EMBEDDING:=embeddinggemma:300m-qat-q8_0}"
  : "${KAI_NUM_CTX:=4096}"
  : "${KAI_BACKUP_DIR:=$KAI_ROOT/backups}"
}

# Mode d'un fichier, en octal, portable macOS (stat -f) / Linux (stat -c).
kai_file_mode() {
  local f="$1"
  [ -e "$f" ] || return 0
  if stat -f '%Lp' "$f" 2>/dev/null; then return 0; fi
  stat -c '%a' "$f" 2>/dev/null || true
}

# --- Réseau -----------------------------------------------------------------
kai_ollama_url() { printf 'http://%s:%s' "$KAI_OLLAMA_HOST" "$KAI_OLLAMA_PORT"; }
kai_webui_url()  { printf 'http://%s:%s' "$KAI_BIND_HOST" "$KAI_WEBUI_PORT"; }

# Un port est-il occupé ?  Utilisé pour l'état, jamais pour scanner un tiers.
kai_port_busy() {
  local port="$1"
  if have lsof; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
  elif have ss; then
    ss -ltn 2>/dev/null | awk '{print $4}' | grep -q ":${port}\$"
  else
    return 1
  fi
}

# Sonde HTTP courte.  Délai volontairement bas : hors ligne, on veut un échec
# immédiat, pas une attente de 30 secondes (§8.1, circuit breaker).
kai_http_ok() {
  local url="$1" timeout="${2:-3}"
  have curl || return 1
  curl -fsS --max-time "$timeout" -o /dev/null "$url" 2>/dev/null
}

# --- Divers -----------------------------------------------------------------
kai_timestamp() { date +%Y%m%d-%H%M%S; }
kai_iso_date()  { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Échappe une chaîne pour l'insérer dans du JSON.
kai_json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' \
    | tr -d '\n'
}

kai_mkdirs() { mkdir -p "$KAI_REPORT_DIR" "$KAI_RUN_DIR"; }
