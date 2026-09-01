#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Recherche de secrets dans l'arbre de travail ET dans l'historique Git.
#
# Scanner l'arbre seul ne sert à rien : une clé committée puis supprimée reste
# dans l'historique, et c'est l'historique qui est poussé sur GitHub (§9.1,
# R-003).
#
# À lancer avant chaque commit.
# ---------------------------------------------------------------------------

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

title "Recherche de secrets"

FOUND=0

# Motifs de clés réelles.  Volontairement spécifiques : un motif trop large
# produit du bruit, et un scanner qui crie tout le temps n'est plus lu.
# Le tiret et le tiret bas font PARTIE des clés modernes : une clé OpenAI
# actuelle s ecrit sk-proj-xxxx, une clé Anthropic sk-ant-api03-xxxx.  Un
# motif qui n accepte que des caractères alphanumériques après « sk- » les
# laisse toutes passer — c est le défaut qui rendait ce scan inoffensif.
PATTERNS='
sk-[A-Za-z0-9_-]{20,}
AIza[0-9A-Za-z_-]{35}
gh[pousr]_[A-Za-z0-9]{36,}
xox[baprs]-[A-Za-z0-9-]{10,}
glpat-[A-Za-z0-9_-]{20,}
-----BEGIN [A-Z ]*PRIVATE KEY-----
'

# --- 1. Arbre de travail ---------------------------------------------------
title "1. Arbre de travail"
TREE_HITS=0
while IFS= read -r pat; do
  [ -n "$pat" ] || continue
  hits="$(grep -rInE "$pat" "$KAI_ROOT" \
    --exclude-dir=.git --exclude-dir=.venv --exclude-dir=node_modules \
    --exclude-dir=data --exclude-dir=models --exclude-dir=backups \
    --exclude='*.lock' 2>/dev/null \
    | grep -v 'secret-scan.sh' || true)"
  if [ -n "$hits" ]; then
    err "Motif trouvé : $pat"
    printf '%s\n' "$hits" | head -5 | sed 's/^/    /'
    TREE_HITS=$((TREE_HITS + 1))
  fi
done <<EOF
$(printf '%s' "$PATTERNS" | grep -v '^$')
EOF
[ "$TREE_HITS" -eq 0 ] && ok "Aucun secret dans l'arbre de travail." \
  || FOUND=$((FOUND + TREE_HITS))

# --- 2. Historique Git -----------------------------------------------------
title "2. Historique Git"
if [ -d "$KAI_ROOT/.git" ] && have git; then
  HIST_HITS=0
  while IFS= read -r pat; do
    [ -n "$pat" ] || continue
    # `git log -G` cherche le motif dans le contenu ajouté ou retiré par
    # chaque commit — donc y compris dans ce qui a été « supprimé » depuis.
    commits="$(git -C "$KAI_ROOT" log --all --oneline -G"$pat" 2>/dev/null | head -5 || true)"
    if [ -n "$commits" ]; then
      err "Motif présent dans l'historique : $pat"
      printf '%s\n' "$commits" | sed 's/^/    /'
      HIST_HITS=$((HIST_HITS + 1))
    fi
  done <<EOF
$(printf '%s' "$PATTERNS" | grep -v '^$')
EOF
  [ "$HIST_HITS" -eq 0 ] && ok "Aucun secret dans l'historique Git." \
    || FOUND=$((FOUND + HIST_HITS))
else
  warn "Pas de dépôt Git — historique non scanné."
fi

# --- 3. .env est-il bien ignoré ? ------------------------------------------
title "3. Configuration"
if [ -f "$KAI_ROOT/.env" ]; then
  if git -C "$KAI_ROOT" check-ignore -q .env 2>/dev/null; then
    ok ".env existe et est bien ignoré par Git."
  else
    err ".env N'EST PAS ignoré par Git — risque de commit d'une clé."
    FOUND=$((FOUND + 1))
  fi
  mode="$(kai_file_mode "$KAI_ROOT/.env")"
  if [ "$mode" = "600" ]; then
    ok "Permissions de .env : 600."
  else
    err "Permissions de .env : $mode (attendu 600).  Corrigez : chmod 600 .env"
    FOUND=$((FOUND + 1))
  fi
else
  info ".env absent (normal avant 'make install')."
fi

if git -C "$KAI_ROOT" ls-files 2>/dev/null | grep -qx '.env'; then
  err ".env EST SUIVI PAR GIT.  Retirez-le : git rm --cached .env"
  FOUND=$((FOUND + 1))
else
  ok ".env n'est pas suivi par Git."
fi

# --- Verdict ---------------------------------------------------------------
title "Résultat"
log ""
if [ "$FOUND" -eq 0 ]; then
  ok "Aucun secret détecté."
  exit 0
fi

err "$FOUND problème(s) détecté(s)."
log ""
log "  Si une clé a été committée puis poussée, elle doit être considérée"
log "  comme compromise.  RÉVOQUEZ-LA CHEZ LE FOURNISSEUR EN PREMIER."
log "  Réécrire l'historique ensuite ne la désactive pas."
log ""
exit 1
