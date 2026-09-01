# KAI-EXEC-007 — V1 sur mesure

**Statut : `À DÉFINIR`** · bloqué par : **validation explicite de la V0 par
Kevin**.

Cette mission ne commence pas avant. Ce n'est pas une formalité : c'est la
protection contre le risque R-011, qui est le risque le plus probable de tout
le projet — construire une belle interface et rater le vol.

## Définir

Remplacer la V0 par un produit personnel durable : interface propre, routage
hybride explicite, mémoire contrôlable, RAG indépendant du fournisseur de
modèle.

## Ce que la V1 apporte, que la V0 ne peut pas donner

| Besoin | V0 | V1 |
|---|---|---|
| Portail de politique `local_only` | ❌ discipline humaine | ✅ mécanisme dans le routeur |
| Mémoire contrôlable (voir, modifier, supprimer) | ❌ historique brut | ✅ quatre couches séparées |
| Indicateur du mode réel (`LOCAL`/`CLOUD`/`RAG`/`WEB`) | ❌ | ✅ |
| Routage automatique avec bouton de désactivation | ❌ | ✅ |
| Estimation du coût avant appel payant | ❌ | ✅ |
| Interface aux couleurs de Kevin | ❌ licence Open WebUI | ✅ code à nous |

## Architecture

Voir [`../architecture/v1-architecture.md`](../architecture/v1-architecture.md).

## Ordre de construction proposé

Chaque étape doit être utilisable avant de passer à la suivante. Ne pas tout
écrire puis tout brancher.

1. **Backend FastAPI + un seul endpoint de chat vers Ollama.** Une interface
   minimale qui parle au modèle local. Rien d'autre.
2. **Routeur de politique déterministe.** Règles explicites (§8.2), pas un
   second LLM qui décide sans contrôle.
3. **Service RAG indépendant** : Docling → découpage → embeddings → Qdrant,
   plus BM25, plus fusion déterministe.
4. **Service mémoire** : quatre couches, statut `proposé/approuvé/rejeté`.
5. **Interface Next.js/PWA** avec les indicateurs de mode et les citations.
6. **Passerelle LiteLLM** et portail de politique cloud.

## Migration depuis la V0

**Par les formats exportés, jamais par manipulation de la base interne
d'Open WebUI** (§12). Écrire directement dans le SQLite d'un logiciel tiers
crée une dépendance à sa structure interne, qui changera sans prévenir et
cassera silencieusement.

Exporter conversations et documents, réimporter par l'API de la V1.

## Critère de bascule

La V1 ne remplace la V0 que lorsqu'elle passe **le même jeu de tests** :
les 30 questions générales, les 20 questions documentaires, et le test à
froid hors ligne de KAI-EXEC-004.

Tant qu'elle n'y arrive pas, la V0 reste le système de vol. Garder les deux
côte à côte coûte peu ; se retrouver sans système qui fonctionne coûte cher.

## Décision attendue de Kevin

Validation explicite de la V0 **et** confirmation que l'interface sur mesure
en vaut l'effort. La réponse « la V0 me suffit » est une réponse parfaitement
valable, et il faut pouvoir la donner sans regret.
