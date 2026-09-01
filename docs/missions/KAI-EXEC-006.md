# KAI-EXEC-006 — Sauvegarde et exploitation

**Statut : `PLANIFIÉ`** · bloqué par : KAI-EXEC-002.

## Définir

Pouvoir arrêter, redémarrer, diagnostiquer, sauvegarder et **restaurer** sans
improviser, y compris hors ligne et sous stress.

## Planifier

Des scripts courts, une fiche d'utilisation très brève, et une restauration
réellement testée.

## Exécuter

Les scripts sont livrés :

| Commande | Rôle |
|---|---|
| `make start` / `make stop` / `make restart` | Cycle de vie |
| `make status` | Services, modèles, **interfaces en écoute**, ressources |
| `make backup` | Archive + SHA-256, `.env` exclu ; `ENCRYPT=1` pour chiffrer |
| `make restore` | Restauration **vers un dossier temporaire** par défaut |
| `make offline-test` | Aptitude au vol |
| `make diagnose` | Rapport complet, sans secret |
| `make flight-check` | Enchaîne scan de secrets, état et test hors ligne |

La fiche d'utilisation courte est la section « Démarrage » du `README.md`, et
`OFFLINE_RUNBOOK.md` pour le vol.

## Critères d'acceptation (§12)

| Critère | Vérification |
|---|---|
| Restauration testée dans un emplacement temporaire | `make restore ARCHIVE=...` sans `IN_PLACE` |
| Checksum | Fichier `.sha256` présent et vérifié avant extraction |
| Sauvegarde chiffrable | `make backup ENCRYPT=1` produit un `.gpg` |
| Aucune clé dans l'archive standard | Le script vérifie lui-même l'absence de `.env` et refuse l'archive sinon |

## Deux choix à connaître

**La restauration ne va pas en place par défaut.** `make restore` extrait vers
un dossier temporaire. Restaurer par-dessus les données vivantes exige
`IN_PLACE=1` **et** de taper `ECRASER`. Une sauvegarde qu'on ne teste jamais
par peur d'écraser la production n'est pas une sauvegarde (R-010) : ce défaut
existe pour qu'on la teste.

**Les clés ne sont pas sauvegardées.** C'est voulu (§9.1). Conséquence à
connaître avant d'en avoir besoin : restaurer ne restaure pas les clés, elles
se reconfigurent depuis le trousseau.

## Rapport créateur

*À remplir.*

## Rapport vérificateur

*À remplir.*

| Contrôle | Résultat |
|---|---|
| Archive créée, taille | |
| SHA-256 vérifié | |
| Absence de `.env` dans l'archive | |
| Restauration temporaire réussie | |
| Nombre de fichiers restaurés | |
| Version chiffrée déchiffrable | |

Verdict :
