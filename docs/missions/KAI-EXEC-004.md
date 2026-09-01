# KAI-EXEC-004 — Mode hors ligne réel

**Statut : `PLANIFIÉ`** · bloqué par : KAI-EXEC-003.

**C'est la mission qui décide si le projet a servi à quelque chose.** Tout le
reste est confort ; celle-ci est la raison d'être de la V0.

## Définir

Le système doit fonctionner après un redémarrage complet, sans aucun réseau :
chat, RAG avec citations, historique. Aucune tentative de téléchargement ne
doit bloquer le démarrage.

## Planifier

Tout précharger : modèles LLM, modèle d'embeddings, paquets Python
verrouillés, exécutables. Activer les options hors ligne. **Ne rien ajouter
d'autre.**

L'OCR, le reranker, Whisper et la synthèse vocale sont **exclus** (décision
D-009) : chacun consomme de la mémoire pendant une conversation, aucun n'est
nécessaire à « chat + RAG + historique », et chacun ajoute une occasion de
casser le démarrage hors ligne. C'est le risque R-011 en action.

## Exécuter

```sh
make offline-test
```

Contrôle : contexte réseau, présence des trois modèles, absence de résolution
de version en ligne, variables `HF_HUB_OFFLINE` et `TRANSFORMERS_OFFLINE`,
services, **génération réelle**, **embeddings réels**, persistance.

## Le test impératif, que le script ne peut pas faire

`make offline-test` vérifie l'autonomie des composants. Il **ne prouve pas**
qu'un démarrage à froid sans réseau fonctionne : il tourne sur un système
déjà démarré, dont les caches sont chauds.

Le test qui compte est manuel (§12) :

1. Couper le Wi-Fi **et** le partage de connexion de l'iPhone.
   *Couper le Wi-Fi seul ne suffit pas : le Mac peut basculer silencieusement
   sur le partage de connexion et masquer une dépendance réseau.*
2. **Redémarrer complètement le Mac.**
3. `make start`, ouvrir <http://127.0.0.1:8080>.
4. Poser une question générale → réponse.
5. Poser une question sur le corpus → réponse **citée**.
6. Vérifier que l'historique précédent est là.

Ne pas confondre les deux tests. Confondre les deux, c'est embarquer avec une
fausse assurance, et le découvrir en vol.

## Critères d'acceptation (§12)

| Critère | Preuve |
|---|---|
| Aucune tentative bloquante de téléchargement | Journaux propres après démarrage à froid |
| Réponse locale | Génération produite, réseau coupé |
| Citation locale | Citation exacte produite, réseau coupé |
| Démarrage documenté | `OFFLINE_RUNBOOK.md` suivi sans improvisation |
| Aucune régression après redémarrage | Historique et collections intacts |

## Rapport créateur

*À remplir.*

## Rapport vérificateur

*À remplir.*

| Contrôle | Résultat | Preuve |
|---|---|---|
| `make offline-test` | | |
| Wi-Fi ET partage coupés | | |
| Redémarrage complet effectué | | |
| Chat sans réseau | | |
| RAG cité sans réseau | | |
| Historique préservé | | |
| Journaux sans tentative réseau | | |

Verdict :

## Décision attendue de Kevin

Validation que la V0 est **apte au vol**. C'est cette validation qui débloque
KAI-EXEC-005 puis, plus tard, KAI-EXEC-007.
