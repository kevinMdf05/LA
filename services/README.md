# services/ — composants métier de la V1

**Vides, délibérément** — voir [`../apps/README.md`](../apps/README.md).

| Dossier | Rôle prévu |
|---|---|
| `router/` | Politique de routage local/cloud, détection de connexion, portail `local_only` |
| `rag/` | Recherche hybride BM25 + vecteurs, fusion, reranking |
| `memory/` | Quatre couches de mémoire, statuts `proposé`/`approuvé`/`rejeté` |
| `ingestion/` | Pipeline documentaire en 12 étapes (`DATA_POLICY.md` §6) |

Conception : [`../docs/architecture/v1-architecture.md`](../docs/architecture/v1-architecture.md).
