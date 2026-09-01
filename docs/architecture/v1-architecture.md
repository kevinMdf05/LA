# Architecture V1 — « Kevin AI »

> **Statut : conception uniquement.** Aucun code de cette architecture n'est
> écrit, délibérément (décision D-010). KAI-EXEC-007 ne commence qu'après
> validation explicite de la V0 par Kevin.

## Vue d'ensemble

```text
Interface Next.js / PWA
        │
        ▼
  API locale FastAPI
        │
        ├─ Routeur de politique
        │     ├─ Ollama          (hors ligne, local)
        │     └─ LiteLLM         (fournisseurs cloud)
        │
        ├─ Service RAG
        │     ├─ Docling         extraction
        │     ├─ BM25            recherche lexicale
        │     ├─ embeddings      multilingues, locaux
        │     ├─ Qdrant          vecteurs + filtrage par métadonnées
        │     └─ reranker        cross-encoder, activable selon la RAM
        │
        ├─ Service mémoire
        │     └─ SQLite          profil, projet, épisodique, historique
        │
        └─ Outils en ligne
              └─ SearXNG         recherche Web auto-hébergée
```

## Pourquoi cette séparation

Chaque frontière existe pour une raison précise :

- **Le frontend ne connaît aucune clé.** C'est la seule façon de garantir
  qu'une clé ne se retrouve pas dans le bundle JavaScript (§9.1, R-003).
- **Le routeur décide, pas l'interface.** Connexion, confidentialité,
  difficulté et préférences sont des règles, et des règles se testent.
- **Le RAG ne dépend pas du fournisseur de modèle.** Changer de modèle ne
  doit pas obliger à réindexer.
- **La mémoire n'est pas mélangée aux documents.** Ce sont deux natures
  différentes : un document est une source citable, un souvenir est une
  affirmation datée dont il faut connaître la provenance.
- **Ollama et les API cloud exposent des interfaces proches**, ce qui évite
  de réécrire l'application pour passer de l'un à l'autre.

## Le routeur — le cœur de la V1

Règles déterministes, dans cet ordre (§8.2) :

1. `mode=local` → Ollama, toujours.
2. Données `local_only` requises → Ollama, ou confirmation explicite.
3. Question dépendant de l'actualité → proposer Web/cloud.
4. Internet absent ou API en échec → repli sur Ollama, **avec indication
   visible**.
5. Modèle local insuffisant → **expliquer la limite** plutôt que masquer
   l'échec.
6. En mode `auto` → règles d'abord ; ne pas laisser un second LLM décider
   sans contrôle.

### Détection de connexion

Ne pas se fier à `navigator.onLine` : il indique qu'une interface réseau
existe, pas qu'elle mène quelque part. Vérifier séparément la santé du
backend, celle d'Ollama, la disponibilité réelle d'un modèle chargé, et
l'accès au fournisseur demandé — avec un délai court et un circuit breaker
(§8.1).

### États affichés

| État | Signification |
|---|---|
| `LOCAL` | Privé, hors ligne possible |
| `CLOUD` | Données envoyées à *[fournisseur]* |
| `RAG` | *X* sources locales consultées |
| `WEB` | Recherche Internet active |
| `FALLBACK` | API indisponible, réponse locale |

Le modèle et le fournisseur réellement utilisés sont visibles **pour chaque
réponse**. Un indicateur global au niveau de la session ne suffit pas : c'est
réponse par réponse que la question « d'où vient cette information » se pose.

## Le portail de politique

C'est le composant qui manque le plus à la V0. Placé entre le service RAG et
la passerelle cloud, il refuse **matériellement** l'envoi d'un passage
étiqueté `local_only`.

Tant qu'il n'existe pas, le risque R-004 reste ouvert et ne doit pas être
présenté comme traité.

## Recherche hybride

BM25 **et** vecteurs, fusionnés par une méthode déterministe, puis reranking
des meilleurs passages.

L'hybride est obligatoire (§6.3), et pour une raison concrète : la recherche
vectorielle seule échoue sur les identifiants exacts — un numéro de
réservation, une référence, un nom propre rare. BM25 les retrouve. À
l'inverse, BM25 seul échoue sur les reformulations. Chacun rattrape l'angle
mort de l'autre.

## Structure du dépôt en V1

```text
apps/web/          Next.js / PWA
apps/api/          FastAPI
services/router/   politique de routage
services/rag/      extraction, indexation, recherche
services/memory/   quatre couches de mémoire
services/ingestion/ pipeline documentaire
```

Ces dossiers existent déjà, vides. C'est délibéré : la structure est décidée,
le code ne l'est pas encore.
