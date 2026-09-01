# KAI-EXEC-001 — Audit matériel et environnement

**Statut : `PLANIFIÉ`** · bloqué par : exécution sur le Mac de Kevin.

## Définir

Identifier les capacités réelles et les contraintes du voyage. La déclaration
« Mac M1, 8 Go » doit être **confirmée par la mesure**, pas supposée. La
donnée la plus importante n'est pas la mémoire — elle est déjà connue — mais
**l'espace disque libre**, qui décide si les 5,64 Go de modèles sont
téléchargeables sans étouffer macOS.

## Planifier

Un script en lecture seule produisant un rapport JSON et un résumé Markdown.
Aucune installation, aucune modification de réglage système, aucune écriture
hors de `reports/`.

## Exécuter

```sh
make hardware
```

Relève : version de macOS et build, architecture, processeur, mémoire
unifiée, pression mémoire au repos, swap utilisé, espace libre du volume de
`$HOME`, batterie, versions des outils, occupation des ports 8080 et 11434.

## Vérifier

Le §12 l'exige explicitement : **comparer le rapport aux commandes système
brutes.** Le vérificateur exécute lui-même, à la main :

```sh
sw_vers
uname -m
sysctl -n hw.memsize
sysctl -n machdep.cpu.brand_string
df -h $HOME
memory_pressure | tail -3
```

et confronte chaque valeur au JSON. Une divergence est une anomalie, même
minime : un rapport qui se trompe sur une valeur vérifiable ne mérite pas
confiance sur les autres.

## Critères d'acceptation

| Critère | Vérification |
|---|---|
| Rapport reproductible | Deux exécutions successives donnent les mêmes valeurs stables |
| Aucune donnée sensible | Relire le JSON : ni nom d'utilisateur inutile, ni chemin privé, ni identifiant matériel |
| Aucune modification système | `git status` propre hors `reports/` ; aucun paquet installé |
| Profil déterminé | Le champ `profile.id` vaut `A` pour 8 Go |
| Espace disque tranché | Verdict `suffisant`, `juste` ou `insuffisant` |

## Rapport créateur

*À remplir après exécution sur le Mac.*

- Commande exécutée :
- Fichiers produits :
- Hypothèses :

## Rapport vérificateur

*À remplir. Le vérificateur note les valeurs relevées à la main en regard de
celles du JSON.*

| Valeur | Commande brute | JSON | Concordance |
|---|---|---|---|
| Version macOS | | | |
| Architecture | | | |
| Mémoire totale | | | |
| Espace libre | | | |

Anomalies relevées :

Verdict :

## Décision attendue de Kevin

**Q-001** — Confirmer que l'espace libre mesuré est réellement mobilisable :
5,64 Go de modèles **plus** 15 à 20 Go de marge (§15).

**Q-004** — Durée d'utilisation souhaitée en vol, sur batterie. La réponse
détermine si le 4B est tenable ou si le 2B doit devenir le modèle par défaut
en déplacement.

## Mission suivante

KAI-EXEC-002, après réponse à Q-001.
