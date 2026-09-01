#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Relève les versions RÉELLEMENT installées et les écrit dans
# reports/versions-installed.md.
#
# Sert à fermer l'anomalie A-001 : les versions d'Ollama et de `uv` ne
# peuvent être épinglées que sur la machine où elles s'installent (§4.1).
# ---------------------------------------------------------------------------

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

kai_load_env
kai_mkdirs
OUT="$KAI_REPORT_DIR/versions-installed.md"

title "Relevé des versions installées"

WEBUI_VERSION="non installé"
if [ -x "$KAI_ROOT/.venv/bin/python" ]; then
  WEBUI_VERSION="$("$KAI_ROOT/.venv/bin/python" -c \
    'import importlib.metadata as m; print(m.version("open-webui"))' 2>/dev/null \
    || printf 'non installé')"
fi

{
  printf '# Versions installées\n\n'
  printf 'Relevé le %s sur %s.\n\n' "$(kai_iso_date)" "$(uname -s)"
  printf 'À reporter dans VERSIONS.md, section « À ÉPINGLER » (anomalie A-001).\n\n'
  printf '| Composant | Version installée |\n|---|---|\n'
  printf '| macOS | %s |\n' "$(sw_vers -productVersion 2>/dev/null || uname -r)"
  printf '| ollama | %s |\n' "$(have ollama && ollama --version 2>&1 | head -1 || printf 'absent')"
  printf '| uv | %s |\n' "$(have uv && uv --version 2>&1 | head -1 || printf 'absent')"
  printf '| python (venv) | %s |\n' "$([ -x "$KAI_ROOT/.venv/bin/python" ] && "$KAI_ROOT/.venv/bin/python" --version 2>&1 || printf 'absent')"
  printf '| open-webui | %s |\n' "$WEBUI_VERSION"
  printf '\n## Modèles\n\n```\n'
  have ollama && ollama list 2>&1 || printf 'ollama absent\n'
  printf '```\n'
} > "$OUT"

cat "$OUT" | sed 's/^/  /'
log ""
ok "Écrit : $OUT"
info "Reportez ces valeurs dans VERSIONS.md, puis committez."
