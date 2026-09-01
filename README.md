# KAI — IA personnelle hybride de Kevin

> Référence : `KAI-MISSION-001 — Plan directeur`, v1.0, 1er septembre 2026
> Propriétaire et décideur final : **Kevin**
> Machine serveur : **Mac Apple Silicon M1, 8 Go de mémoire unifiée**

Une IA personnelle accessible dans le navigateur sur `http://127.0.0.1`, qui
fonctionne **hors ligne** (modèle local), **en ligne** (API cloud + Web) et
**sur les documents de Kevin** (RAG local avec citations), sans jamais exposer
de clé API ni de donnée privée.

---

## ⚠️ État réel du projet — à lire en premier

Ce dépôt contient **le système exécutable, pas encore un système exécuté.**

Le plan directeur exige des mesures réelles sur le Mac M1 de Kevin : audit
matériel, téléchargement des modèles, benchmark mémoire, test à froid en mode
avion. **Aucune de ces mesures ne peut être produite depuis un conteneur Linux
distant** — c'est la machine de Kevin qui est le sujet de la mesure.

Ce que ce dépôt livre aujourd'hui :

| Livrable (§18) | État |
|---|---|
| Dépôt propre avec README | ✅ Livré |
| Scripts start/stop/status/backup/restore/offline-test/diagnose | ✅ Livrés, à exécuter sur le Mac |
| `.env.example` sans secret | ✅ Livré |
| `docker-compose.yml` avec versions épinglées | ✅ Livré (chemin alternatif, non recommandé sur 8 Go) |
| `SECURITY.md`, `DATA_POLICY.md`, `OFFLINE_RUNBOOK.md` | ✅ Livrés |
| `VERSIONS.md`, `DECISIONS.md`, `ANOMALIES.md`, `ITERATIONS.md` | ✅ Livrés |
| Jeu d'évaluation (30 + 20 questions) et harnais de mesure | ✅ Livré, résultats vides |
| `hardware-report.json` | ⏳ **Produit par Kevin** via `make hardware` |
| Liste exacte des modèles téléchargés et leur taille | ⏳ **Produite par Kevin** via `make preload` |
| Rapport final avec verdict | ⏳ `BLOQUÉ EN ATTENTE D'EXÉCUTION MACHINE` |

**Verdict global actuel : `PLANIFIÉ` — aucune mission n'est `VALIDÉE`.**
Le détail mission par mission est dans [`docs/missions/`](docs/missions/) et
le journal de boucle dans [`ITERATIONS.md`](ITERATIONS.md).

---

## Démarrage — le chemin le plus court

Sur le Mac, dans un Terminal, depuis le dossier du dépôt :

```sh
make hardware     # KAI-EXEC-001 : audit non destructif → reports/hardware-report.json
make install      # KAI-EXEC-002 : Ollama + Open WebUI épinglé dans un venv uv
make preload      # KAI-EXEC-002 : télécharge les modèles épinglés (≈ 5,64 Go)
make start        # lance Ollama + Open WebUI sur 127.0.0.1:8080
```

Puis ouvrir <http://127.0.0.1:8080>.

Pour arrêter : `make stop`. Pour l'état : `make status`.

**Avant de partir en vol, la seule commande qui compte :**

```sh
make offline-test
```

Elle vérifie qu'aucun composant ne réclame le réseau. La procédure complète
de vol — y compris le redémarrage à froid sans Wi-Fi, qui ne peut pas être
automatisé — est dans [`OFFLINE_RUNBOOK.md`](OFFLINE_RUNBOOK.md).

---

## Deux livraisons, dans cet ordre

### V0 « Flight Ready » — le filet de sécurité

`Ollama` (natif macOS) + `Open WebUI` (venv `uv`, version épinglée). C'est un
assemblage de composants existants, pas du code sur mesure. **Elle doit être
utilisable avant le départ.**

```text
Navigateur (127.0.0.1:8080)
  └─ Open WebUI ──┬─ Ollama → modèles locaux (qwen3.5 4B / 2B)
                  ├─ RAG local → documents + citations
                  └─ API cloud (facultatif, hors ligne : inactif)
```

### V1 « Kevin AI » — le produit durable

Interface Next.js/PWA, backend FastAPI, routeur de politique, RAG indépendant
(Docling + Qdrant + BM25), mémoire contrôlable. **Gelée jusqu'à validation
explicite de la V0 par Kevin** (§12, KAI-EXEC-007). Les dossiers `apps/` et
`services/` ne contiennent aujourd'hui que la conception, délibérément :
construire la V1 avant que la V0 ne vole, c'est le risque R-011.

Conception détaillée : [`docs/architecture/v1-architecture.md`](docs/architecture/v1-architecture.md).

---

## Ce que ce système ne fait pas

Une vérité technique à garder, parce qu'elle protège des mauvaises décisions
(§1) :

- Il ne « contient pas Internet ». Le modèle local a une connaissance figée à
  sa date d'entraînement. Ajouter des téraoctets de fichiers **n'augmente pas**
  l'intelligence du modèle — une ingestion massive et mal classée **dégrade**
  la précision de la recherche.
- Il ne doit **jamais** présenter une réponse hors ligne comme une information
  actuelle. Sur toute question dépendant de l'actualité, il signale que sa
  connaissance peut être dépassée, ou demande l'autorisation d'utiliser le Web.
- Il ne s'expose pas sur Internet, ne prend pas d'action externe irréversible
  sans validation humaine, et ne fait pas de fine-tuning en V0.

---

## Carte du dépôt

```text
scripts/          Exploitation V0 : audit, install, start/stop, backup, offline-test
tests/evaluation/ 30 questions générales + 20 questions RAG, versionnées, + harnais
docs/missions/    KAI-EXEC-001..007 : critères, rapport créateur, rapport vérificateur
docs/architecture/ V0 et V1
docs/security/    Modèle de menace
infra/compose/    docker-compose.yml épinglé (chemin alternatif)
apps/ services/   V1 — conception uniquement, gelée jusqu'à validation V0
data/ models/     Ignorés par Git : jamais de document personnel ni de poids ici
```

## Documents de gouvernance

| Fichier | Rôle |
|---|---|
| [`VERSIONS.md`](VERSIONS.md) | Version, date, licence et URL de chaque composant épinglé |
| [`DECISIONS.md`](DECISIONS.md) | Décisions engagées, et celles en attente de Kevin (§17) |
| [`ANOMALIES.md`](ANOMALIES.md) | Anomalies ouvertes et registre des risques (§16) |
| [`ITERATIONS.md`](ITERATIONS.md) | Journal Loop Engineering, statut par mission |
| [`SECURITY.md`](SECURITY.md) | Clés, réseau, modèle de menace (§9) |
| [`DATA_POLICY.md`](DATA_POLICY.md) | Collections, sensibilité, politique d'envoi cloud (§6) |
| [`OFFLINE_RUNBOOK.md`](OFFLINE_RUNBOOK.md) | Procédure de vol, test à froid, dépannage sans réseau |

---

## Prochaine action attendue de Kevin

1. Exécuter `make hardware` sur le Mac et **relire** `reports/hardware-report.json`.
2. Valider l'espace disque mobilisable (il faut ≈ 5,64 Go de modèles **plus**
   15–20 Go de marge libre après téléchargement — §5, §15).
3. Répondre aux questions ouvertes de [`DECISIONS.md`](DECISIONS.md)
   (fournisseurs API déjà possédés, appareils d'accès souhaités).

Rien de payant, rien d'irréversible et rien de destructif n'est déclenché par
les trois premières commandes.
