# ITERATIONS — journal Loop Engineering

Boucle appliquée à chaque mission (§12, §19) :
**définir → planifier → exécuter → vérifier → critiquer → corriger →
revérifier → valider ou bloquer.**

Statuts autorisés (§13) :
`À DÉFINIR` · `PLANIFIÉ` · `EN COURS` · `À VÉRIFIER` · `CORRECTION REQUISE` ·
`BLOQUÉ` · `VALIDÉ TECHNIQUEMENT` · `VALIDÉ PAR KEVIN`

---

## Tableau de bord

| Mission | Objet | Statut | Bloqué par |
|---|---|---|---|
| KAI-EXEC-000 | Remise à zéro du dépôt et armature du projet | **VALIDÉ TECHNIQUEMENT** | validation de Kevin |
| KAI-EXEC-001 | Audit matériel et environnement | `PLANIFIÉ` | exécution sur le Mac |
| KAI-EXEC-002 | V0 locale minimale | `PLANIFIÉ` | KAI-EXEC-001, Q-001 |
| KAI-EXEC-003 | Base documentaire locale | `PLANIFIÉ` | KAI-EXEC-002, Q-005 |
| KAI-EXEC-004 | Mode hors ligne réel | `PLANIFIÉ` | KAI-EXEC-003 |
| KAI-EXEC-005 | API cloud | `PLANIFIÉ` | validation V0, Q-003 |
| KAI-EXEC-006 | Sauvegarde et exploitation | `PLANIFIÉ` | KAI-EXEC-002 |
| KAI-EXEC-007 | V1 sur mesure | `À DÉFINIR` | **validation explicite de la V0 par Kevin** |

Aucune mission ne passe à `VALIDÉ PAR KEVIN` sans son accord explicite.

---

## Itération 000 — Remise à zéro et armature du projet

**Date :** 2026-09-01 · **Branche :** `claude/kai-mission-001-hybrid-ai-8a1pe3`

### Définir
Le dépôt contenait un site vitrine Next.js « L.A. travel » (22 fichiers), sans
rapport avec KAI-MISSION-001. Kevin demande de repartir de zéro sur le plan
directeur. Objectif de l'itération : livrer l'armature exécutable — scripts,
documents de gouvernance, jeu d'évaluation, fiches de mission — sans inventer
de résultat de mesure.

### Planifier
1. Retirer les fichiers du site de l'arbre, **sans** réécrire l'historique ni
   supprimer la branche d'origine (perte de données autrement irréversible).
2. Vérifier sur les sources officielles les versions épinglables à distance.
3. Écrire les documents de gouvernance, les scripts V0, le jeu d'évaluation
   et les sept fiches de mission.
4. Vérifier ce qui est vérifiable ici ; déclarer explicitement le reste.

### Exécuter
- `git rm -r .` sur la branche KAI (22 fichiers retirés, historique intact).
- Versions relevées : tags Ollama `qwen3.5` et `embeddinggemma`, PyPI
  `open-webui` → `VERSIONS.md`.
- 11 scripts d'exploitation, 8 documents de gouvernance, 50 questions
  d'évaluation, 7 fiches de mission, `docker-compose.yml` épinglé.

### Vérifier — *rapport du vérificateur, rôle séparé du créateur (§13)*

Le vérificateur ne retient pas « la commande s'est terminée sans erreur »
comme preuve. Contrôles effectués :

| Contrôle | Méthode | Résultat |
|---|---|---|
| Syntaxe de tous les scripts shell | `bash -n` sur chaque fichier | ✅ 11/11 |
| Compatibilité bash 3.2 (macOS) | Recherche de `declare -A`, `mapfile`, `readarray`, `${x^^}` | ✅ aucune occurrence |
| Absence de secret dans le dépôt | `scripts/secret-scan.sh` sur l'arbre **et** l'historique | ✅ aucun secret |
| Le scanner détecte-t-il vraiment ? | 4 formes de clés réelles plantées puis retirées | ✅ 4/4 après correction — voir A-005 |
| La suite de tests détecte-t-elle une régression ? | 3 sabotages : liaison `0.0.0.0`, injection retirée du corpus, tag flottant | ✅ chaque sabotage fait échouer le test attendu |
| Absence de tag flottant | Recherche de `:latest`, `:main` dans scripts et compose | ✅ aucun |
| Écoute réseau limitée à la boucle locale | Lecture des liaisons dans scripts et compose | ✅ `127.0.0.1` partout |
| `hardware-report.sh` produit un JSON valide | Exécution réelle + `jq .` | ✅ JSON valide (sur Linux, en mode dégradé) |
| Jeu d'évaluation lisible par le harnais | `python3 -c` chargement des 50 questions | ✅ 30 + 20 chargées |
| Cohérence des tailles de modèles | Somme des tailles annoncées vs source | ✅ 5,64 Go |
| Le `Makefile` n'appelle que des cibles existantes | Lecture croisée cibles ↔ scripts | ✅ |

### Critiquer

Trois faiblesses que le vérificateur retient contre cette itération :

1. **Aucune preuve d'exécution macOS.** Les scripts sont syntaxiquement
   corrects et leur logique de secours est exercée sur Linux, mais
   `sw_vers`, `sysctl hw.memsize`, `memory_pressure` et `ollama` n'ont **pas**
   tourné. Une erreur de nom d'option macOS ne serait pas détectée ici.
   → Anomalie A-002, et c'est la raison pour laquelle aucun statut de mission
   ne dépasse `PLANIFIÉ`.
2. **Deux versions non épinglées** (Ollama, `uv`) → anomalie A-001.
3. **Le scanner de secrets était inopérant sur les clés modernes.** Trouvé
   en le testant contre une vraie forme de clé plutôt qu'en le lançant sur un
   dépôt propre. Corrigé et revérifié → anomalie A-005, fermée. La leçon
   dépasse ce script : un contrôle qui ne trouve jamais rien n'a pas encore
   fait la preuve qu'il fonctionne.
4. **Le portail de politique cloud (R-004) est une politique écrite, pas un
   mécanisme.** En V0, ce qui empêche réellement une fuite vers le cloud,
   c'est l'absence de clé API et `KAI_CLOUD_BUDGET_EUR=0` — pas un contrôle
   technique. Le vrai portail est un composant V1.

### Corriger
- Ajout de `scripts/check-versions.sh` et de la cible `make versions` pour
  fermer A-001 le jour de l'installation.
- `hardware-report.sh` détecte le système et signale explicitement un rapport
  `degraded` hors macOS, au lieu de produire des valeurs trompeuses.
- Le README et `ANOMALIES.md` déclarent en tête ce qui n'est **pas** mesuré,
  plutôt que de le laisser deviner.

### Revérifier
Contrôles rejoués après correction : `bash -n` 12/12, suite d'intégration
**67 tests, 0 échec**, scanner de secrets validé contre 4 formes de clés
réelles, `hardware-report.json` valide et portant `"status": "degraded"`
hors macOS.

Deux défauts trouvés par la suite de tests elle-même ont été corrigés à la
source plutôt qu'en assouplissant le test : une incohérence de taille de
modèles entre le README (5,6 Go) et le reste du dépôt (5,64 Go), et deux
contrôles qui se détectaient eux-mêmes.

### Verdict
**`VALIDÉ TECHNIQUEMENT`** pour ce qui était réalisable hors de la machine
cible. **`BLOQUÉ`** pour tout ce qui exige le Mac.

**Décision attendue de Kevin :** répondre à Q-001 (espace disque) et Q-006
(sort de l'ancienne branche), puis exécuter `make hardware`.

---

## Itération 001 — *à ouvrir après `make hardware`*

Réservée à KAI-EXEC-001. À remplir avec : rapport créateur (commandes et
sortie), rapport vérificateur (comparaison du JSON aux commandes système
brutes, comme l'exige le §12), profil matériel confirmé (A/B/C/D), et décision
de Kevin sur l'espace disque mobilisable.
