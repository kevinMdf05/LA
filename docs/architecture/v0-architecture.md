# Architecture V0 — « Flight Ready »

## Le principe

La V0 n'est pas un produit, c'est un **filet de sécurité opérationnel**. On
assemble des composants existants et éprouvés, on n'écrit pas de code
applicatif. Objectif unique : que Kevin ait une IA utilisable en vol.

```text
Navigateur (127.0.0.1:8080)
       │
       ▼
  Open WebUI 0.11.3            interface, historique, collections, RAG
       │
       ├──────────────► Ollama (127.0.0.1:11434)
       │                   ├─ qwen3.5:4b-q4_K_M    LLM principal      3,4 Go
       │                   ├─ qwen3.5:2b-q4_K_M    LLM de secours     1,9 Go
       │                   └─ embeddinggemma:300m  embeddings         338 Mo
       │
       └──────────────► API cloud (facultatif, inactif hors ligne)
```

Tout tient sur la boucle locale. Rien n'écoute au-delà de `127.0.0.1`.

## Pourquoi natif, et pas Docker

Sur le Mac M1 8 Go, Docker Desktop fait tourner une machine virtuelle Linux
qui réserve plusieurs gigaoctets en permanence, et Ollama en conteneur sur
macOS n'accède pas au GPU Apple Silicon : l'inférence retombe sur le CPU.

Sur 8 Go de mémoire unifiée partagée entre le système, le modèle et le cache
de contexte, ce n'est pas défendable (décision D-007).
`infra/compose/docker-compose.yml` reste livré pour les machines 16 Go et
plus.

## Le budget mémoire, qui commande tout le reste

C'est la contrainte dont découlent presque toutes les décisions :

| Poste | Ordre de grandeur |
|---|---|
| macOS et applications de base | ~3 Go |
| Poids du modèle 4B en Q4 | 3,4 Go |
| Cache de contexte à 4096 tokens | quelques centaines de Mo |
| **Reste disponible** | **étroit** |

Conséquences directes :

- **Un seul modèle chargé** (`OLLAMA_MAX_LOADED_MODELS=1`).
- **Aucun parallélisme** (`OLLAMA_NUM_PARALLEL=1`).
- **Contexte à 4096**, pas les 256K annoncés par le modèle. Le cache de
  contexte croît avec la longueur et devient vite le premier poste mémoire,
  avant les poids eux-mêmes (R-008).
- **Déchargement après 5 minutes** d'inactivité, pour rendre la RAM à macOS.
- **Pas de reranker, pas d'OCR, pas de Whisper, pas de TTS** en V0
  (décision D-009).

## Persistance

| Donnée | Emplacement | Survit au redémarrage |
|---|---|---|
| Poids des modèles | `~/.ollama` | ✅ |
| Conversations, collections, index | `data/webui` | ✅ |
| Configuration | `.env` (permissions 600) | ✅ |
| Journaux | `logs/` | ✅ |
| PID des processus | `.run/` | ❌ (volontaire) |

Aucun de ces emplacements n'est dans Git, sauf `.env.example`.

## Ce que la V0 ne fait pas

Ce sont des limites assumées, pas des oublis :

- Pas de portail technique pour la politique `local_only` — ce qui protège,
  c'est l'absence de clé API (voir `DATA_POLICY.md` §4).
- Pas de mémoire contrôlable — seulement un historique de conversation.
- Pas d'indicateur `LOCAL`/`CLOUD`/`RAG`/`WEB` unifié.
- Pas d'estimation de coût avant appel payant.
- Pas de personnalisation de marque (licence Open WebUI, anomalie A-004).

Chacune de ces limites est un livrable de la V1 (KAI-EXEC-007).
