# VERSIONS — composants épinglés

Règle (§4.1) : **aucun tag flottant en livraison.** Pas de `latest`, pas de
`main`. Chaque composant est épinglé avec sa version, la date de vérification,
sa licence et l'URL officielle.

Deux catégories de lignes ci-dessous :

- **VÉRIFIÉ** — version relevée sur la source officielle à la date indiquée.
- **À ÉPINGLER** — ne peut être relevée que sur le Mac, le jour de
  l'installation. `scripts/check-versions.sh` relève la version réellement
  installée et l'inscrit dans `reports/versions-installed.md`. Kevin (ou
  Claude) reporte ensuite la valeur ici et committe.

Vérifier à nouveau le jour de l'installation : une version peut avoir changé,
et une licence aussi.

---

## Modèles Ollama — VÉRIFIÉ le 2026-09-01

Relevés sur `https://ollama.com/library/<modele>/tags`.

| Rôle | Tag épinglé | Taille | Licence | Source |
|---|---|---:|---|---|
| LLM principal | `qwen3.5:4b-q4_K_M` | 3,4 Go | Apache-2.0 (à reconfirmer sur la fiche modèle) | <https://ollama.com/library/qwen3.5/tags> |
| LLM secours | `qwen3.5:2b-q4_K_M` | 1,9 Go | Apache-2.0 (à reconfirmer) | <https://ollama.com/library/qwen3.5/tags> |
| Embeddings | `embeddinggemma:300m-qat-q8_0` | 338 Mo | Gemma Terms of Use (à lire avant usage) | <https://ollama.com/library/embeddinggemma/tags> |

**Total à télécharger : ≈ 5,64 Go.**

Notes de sélection :

- `qwen3.5:4b` et `qwen3.5:4b-q4_K_M` pèsent tous deux 3,4 Go : le tag par
  défaut *est* la quantification Q4_K_M. On épingle quand même le tag
  explicite, pour que le jour où le tag par défaut change, rien ne bouge ici.
- Les variantes `-mlx`, `-bf16`, `-mxfp8`, `-nvfp4` sont **écartées** : 4,0 à
  9,3 Go, sans marge sur 8 Go de mémoire unifiée (§5, R-001).
- La fiche annonce une fenêtre de **256K** tokens. Elle n'est **pas** utilisée :
  contexte initial 4096 (§5, R-008). Le cache de contexte est le premier
  facteur limitant sur cette machine, avant les poids.
- Embeddings : la variante QAT `q8_0` (338 Mo) est retenue plutôt que `bf16`
  (622 Mo) pour la marge mémoire. `300m-qat-q4_0` (239 Mo) est le repli si la
  pression mémoire l'exige. **Le choix final doit passer par le benchmark de
  recherche exigé au §5** — il n'est pas encore fait.

### Alternatives évaluées et écartées pour la V0

| Modèle | Raison de l'exclusion |
|---|---|
| Tout modèle ≥ 9B | Poids + cache > mémoire disponible sur 8 Go (§5) |
| `gpt-oss:20b` | Hors profil A ; réservé aux profils C/D |
| Gemma 4 E2B/E4B/12B | Exclu explicitement de la V0 par le plan (§5) |
| Reranker cross-encoder | **Désactivé en V0** ; activation seulement si le benchmark montre une marge |

---

## Logiciels — Open WebUI VÉRIFIÉ le 2026-09-01

| Composant | Version | Date | Licence | Source |
|---|---|---|---|---|
| Open WebUI | `0.11.3` | publiée 2026-08-31 | **Open WebUI License** — *pas* une licence libre standard | <https://pypi.org/project/open-webui/> |
| Python | `>=3.11, <3.13` | contrainte de open-webui 0.11.3 | PSF | <https://www.python.org/> |

> ⚠️ **Point de licence à porter à la connaissance de Kevin.** La licence
> Open WebUI interdit d'altérer, retirer, masquer ou remplacer la marque
> « Open WebUI », sauf cas limités. Pour un usage strictement personnel et
> local, cela ne pose pas de problème. Cela **contraint en revanche** toute
> idée de « rebrander » l'interface V0 en « Kevin AI ». C'est un argument de
> plus pour que la V1 soit une interface distincte (§3.2), et non un
> Open WebUI repeint. → Voir `DECISIONS.md`, D-003.

---

## Logiciels — À ÉPINGLER le jour de l'installation

Ces versions dépendent de ce qui s'installe réellement sur le Mac. Elles ne
peuvent pas être décidées à l'avance de façon honnête.

| Composant | Comment épingler | Source officielle |
|---|---|---|
| Ollama (app macOS) | `ollama --version` après installation → reporter ici | <https://docs.ollama.com/macos> |
| `uv` | `uv --version` après installation → reporter ici | <https://docs.astral.sh/uv/> |
| macOS | `sw_vers -productVersion` → déjà capturé dans `hardware-report.json` | — |

Commande : `make versions` (`scripts/check-versions.sh`).

Le venv Open WebUI est verrouillé par `scripts/install-v0.sh`, qui installe la
version exacte ci-dessus puis écrit un `requirements.lock` complet
(`uv pip freeze`) dans `infra/` — c'est ce fichier, et non `open-webui` seul,
qui garantit un réassemblage identique hors ligne (R-006).

---

## Composants V1 — non installés, non épinglés

Épinglés au démarrage de KAI-EXEC-007 seulement, jamais avant : épingler une
version qu'on n'installe pas produit une documentation fausse dès le premier
mois.

| Composant | Rôle prévu | Source |
|---|---|---|
| FastAPI + Pydantic | Backend V1 | <https://fastapi.tiangolo.com/> |
| Next.js | Interface V1 / PWA | <https://nextjs.org/> |
| LiteLLM | Passerelle multi-fournisseurs | <https://docs.litellm.ai/> |
| Qdrant | Base vectorielle | <https://qdrant.tech/documentation/quickstart/> |
| Docling | Extraction documentaire | <https://docling-project.github.io/docling/> |
| SearXNG | Recherche Web auto-hébergée | <https://docs.searxng.org/> |
| faster-whisper | Transcription (option) | <https://github.com/SYSTRAN/faster-whisper> |

---

## Journal des vérifications

| Date | Qui | Portée | Résultat |
|---|---|---|---|
| 2026-09-01 | Claude | Tags Ollama qwen3.5 + embeddinggemma, PyPI open-webui | Versions et tailles ci-dessus confirmées sur les sources officielles |
| 2026-09-01 | Claude | Versions Ollama / uv | **Non relevées** — l'API GitHub est inaccessible depuis l'environnement d'exécution. Reportées à l'installation. Anomalie A-001. |
