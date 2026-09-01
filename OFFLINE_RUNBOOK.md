# OFFLINE_RUNBOOK — utiliser KAI en avion

Référence : KAI-MISSION-001 §12 (KAI-EXEC-004), risques R-002 et R-007.

Ce document est fait pour être lu **sans réseau**, éventuellement stressé, à
11 000 mètres. Il est volontairement court et impératif.

---

## A. Avant le départ — la veille, pas le matin même

À faire **avec** une connexion, dans cet ordre :

```sh
make preload        # télécharge les 3 modèles épinglés (≈ 5,64 Go)
make start
make offline-test   # vérifie qu'aucun composant ne réclame le réseau
```

`make offline-test` doit se terminer par `RÉSULTAT : PRÊT POUR LE VOL`.
S'il affiche autre chose, **ne pas partir en considérant que ça marchera** :
la cause est listée dans sa sortie.

### Le test qui compte vraiment (§12, non automatisable)

Un test logiciel ne prouve pas qu'on redémarre sans réseau. Faire ceci **une
fois**, en vrai, avant le vol :

1. Couper le Wi-Fi **et** le partage de connexion de l'iPhone.
   *Couper le Wi-Fi seul ne suffit pas : le Mac peut basculer silencieusement
   sur le partage de connexion et masquer une dépendance réseau.*
2. **Redémarrer complètement le Mac.** Pas fermer le couvercle : redémarrer.
3. Ouvrir un Terminal, aller dans le dossier du dépôt, `make start`.
4. Ouvrir <http://127.0.0.1:8080>.
5. Poser une question générale → une réponse doit arriver.
6. Poser une question sur un document ingéré → la réponse doit **citer** sa
   source.
7. Vérifier que l'historique des conversations précédentes est toujours là.

Si l'une de ces sept étapes échoue, c'est R-007, et c'est à corriger avant le
départ — pas en vol.

---

## B. En vol — démarrage

```sh
cd <dossier du dépôt>
make start
```

Puis <http://127.0.0.1:8080>.

Le premier message est plus lent que les suivants : le modèle se charge en
mémoire. C'est normal, ne pas relancer la commande.

---

## C. En vol — économiser mémoire et batterie

Sur 8 Go de mémoire unifiée, l'IA locale et les outils de développement ne
tiennent pas ensemble.

**Avant d'utiliser KAI en vol, fermer :** Docker Desktop, VS Code, Claude
Code, et les onglets de navigateur inutiles.

Surveiller la **pression mémoire** dans Moniteur d'activité (onglet Mémoire) :

| Couleur | Signification | Action |
|---|---|---|
| 🟢 Vert | Marge suffisante | Continuer |
| 🟡 Jaune | macOS commence à comprimer | Fermer des applications |
| 🔴 Rouge | Swap actif, tout ralentit | Passer au modèle de secours (ci-dessous) |

### Passer au modèle de secours

Dans Open WebUI, sélectionner `qwen3.5:2b-q4_K_M` dans le menu de modèle.
Il pèse 1,9 Go au lieu de 3,4 Go : moins bon en rédaction et en raisonnement,
mais il répond quand le 4B fait ramer la machine.

C'est la manœuvre à connaître par cœur. Elle sauve une session de travail.

---

## D. Ce qui ne marche pas hors ligne — et c'est normal

| Fonction | Hors ligne |
|---|---|
| Chat avec le modèle local | ✅ |
| Questions sur les documents ingérés, avec citations | ✅ |
| Historique des conversations | ✅ |
| Ingestion d'un nouveau document | ✅ (modèle d'embeddings déjà local) |
| Recherche Web | ❌ |
| Modèles cloud (OpenAI, Anthropic…) | ❌ |
| Information postérieure à l'entraînement du modèle | ❌ |

**Point de vigilance.** Hors ligne, le modèle répond depuis une connaissance
**figée à sa date d'entraînement**. Sur une question d'actualité, il peut
répondre avec assurance et se tromper. Ne pas traiter une réponse hors ligne
comme une information à jour (§1).

---

## E. Dépannage sans réseau

### La page ne s'ouvre pas

```sh
make status
```

Si Open WebUI n'est pas listé : `make stop && make start`, puis réessayer.

### « Aucun modèle disponible »

```sh
ollama list
```

Les trois modèles épinglés doivent apparaître. S'ils manquent, ils n'ont pas
été téléchargés avant le départ : **rien à faire en vol**, c'est R-002.

### Réponses extrêmement lentes

1. Vérifier la pression mémoire (section C).
2. Passer au modèle `2b`.
3. Fermer tout le reste.

### Un composant essaie de télécharger quelque chose

C'est une régression : `HF_HUB_OFFLINE=1` et `TRANSFORMERS_OFFLINE=1` doivent
être dans `.env`. Vérifier :

```sh
grep OFFLINE .env
```

Puis `make stop && make start`. Noter l'incident dans `ANOMALIES.md` au
retour — c'est exactement le risque R-002, et il mérite d'être corrigé pour
le vol suivant.

### Diagnostic complet

```sh
make diagnose
```

Écrit un rapport dans `reports/`. Il ne contient ni secret, ni contenu de
document.

---

## F. À l'atterrissage

```sh
make backup
```

Sauvegarde les conversations et l'index avant toute autre manipulation.
Puis consigner dans `ANOMALIES.md` ce qui a mal fonctionné en vol, tant que
c'est frais.
