# KAI-EXEC-005 — API cloud

**Statut : `PLANIFIÉ`** · bloqué par : validation de la V0 par Kevin, et
question Q-003.

**Ne pas commencer cette mission avant que la V0 vole.** Ajouter des
fournisseurs cloud avant que le hors-ligne soit prouvé, c'est le risque R-011,
et c'est la façon la plus courante de rater un départ.

## Définir

Pouvoir utiliser un modèle cloud **quand il y a du réseau**, sans jamais
exposer de clé et sans jamais envoyer au cloud une donnée `local_only`.

## Planifier

**Un seul fournisseur d'abord.** Brancher trois API le même jour rend
impossible d'attribuer une fuite ou un dépassement de budget à l'une d'elles.

Clé dans le trousseau macOS, ou à défaut dans `.env` en permissions 600.
Jamais dans le frontend, jamais dans Git, jamais dans un journal.

## Exécuter

1. Répondre à Q-003 : quels fournisseurs Kevin possède déjà.
2. Fixer `KAI_CLOUD_BUDGET_EUR` à une valeur non nulle et **délibérée**.
3. Ajouter une clé, un seul fournisseur.
4. Configurer un plafond de dépense **chez le fournisseur aussi** — une limite
   côté client ne protège pas d'une boucle qui part en vrille.
5. Configurer des délais courts et un circuit breaker (§8.1).
6. Tester le basculement : couper le réseau pendant une génération cloud.

## Critères d'acceptation (§12)

| Critère | Vérification |
|---|---|
| Clé absente du frontend | Inspecter le bundle JavaScript servi, y chercher la clé |
| Clé absente des journaux | `grep` sur `logs/` et sur les rapports de diagnostic |
| Clé absente de Git | `make secret-scan` — arbre **et** historique |
| Échec cloud → repli local | Couper le réseau en cours de génération, observer le repli |
| Fournisseur affiché | Chaque réponse indique son origine |
| Coût enregistré | Un appel payant laisse une trace de coût |
| Données `local_only` bloquées | Poser une question sur une collection privée en mode cloud |

## Le point difficile, à ne pas se cacher

En V0, **il n'existe pas de portail technique** qui empêche l'envoi d'un
passage `local_only` vers le cloud. Open WebUI ne connaît pas nos étiquettes
de sensibilité. Ce qui protège aujourd'hui, c'est l'absence de clé.

Dès qu'une clé existe, cette protection tombe.

Deux options honnêtes, à trancher avec Kevin :

1. **Séparer les usages** : n'utiliser le cloud que sur des conversations sans
   collection privée sélectionnée. Discipline humaine, pas garantie technique.
2. **Attendre la V1** : le portail de politique est un composant du routeur
   (KAI-EXEC-007), et c'est le seul mécanisme qui garantit vraiment le blocage.

Le risque R-004 reste **ouvert** tant que ce portail n'existe pas. Ne pas le
présenter comme traité.

## Rapport créateur

*À remplir.*

## Rapport vérificateur

*À remplir.*

Verdict :

## Décision attendue de Kevin

**Q-003** — Quel fournisseur brancher en premier, et quel plafond mensuel.

Puis : accepter l'option 1 (discipline) ou attendre la V1 (option 2).
