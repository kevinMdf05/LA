# KAI-EXEC-002 — V0 locale minimale

**Statut : `PLANIFIÉ`** · bloqué par : KAI-EXEC-001 et la question Q-001.

## Définir

Un chat local fonctionnel dans le navigateur, sans aucune API, qui survit à
un redémarrage complet de la machine.

## Planifier

Ollama natif macOS + Open WebUI `0.11.3` dans un venv `uv`, versions
épinglées, données persistantes hors du venv (décision D-007).

Deux commandes séparées, et c'est délibéré : `make install` n'engage aucun
téléchargement de modèle, `make preload` annonce 5,64 Go et demande
confirmation avant de les télécharger (§19).

## Exécuter

```sh
make install     # Ollama vérifié, venv créé, open-webui==0.11.3, requirements.lock
make preload     # annonce la taille, demande confirmation, télécharge, inventorie
make start       # 127.0.0.1:8080
```

## Vérifier

`make status` ne suffit pas — il dit que les services répondent, pas qu'ils
fonctionnent. Contrôles observables :

1. Ouvrir <http://127.0.0.1:8080>, poser une question, obtenir une réponse.
2. Vérifier que le modèle utilisé est **affiché** dans l'interface.
3. Basculer sur `qwen3.5:2b-q4_K_M` et poser la même question.
4. Couper le Wi-Fi et recommencer : la réponse doit arriver identiquement.
5. **Redémarrer le Mac**, relancer `make start`, retrouver l'historique.
6. Mesurer le temps de réponse : `make eval --limit 5`.

## Critères d'acceptation (§12)

| Critère | Preuve attendue |
|---|---|
| Chat local fonctionnel | Une réponse produite, sans réseau |
| Redémarrage réussi | Après reboot, `make start` suffit ; historique intact |
| Aucune API nécessaire | `.env` sans clé, et pourtant le chat répond |
| Modèle clairement affiché | Capture ou observation de l'interface |
| Temps de réponse mesuré | TTFT et tok/s relevés par `make eval` |

## Points de vigilance

- **Ne pas lancer Docker Desktop, VS Code et Claude Code pendant la mesure.**
  Un benchmark fait avec 4 Go déjà consommés par les outils ne mesure pas le
  modèle, il mesure l'encombrement de la machine.
- Le premier message après démarrage est lent : c'est le chargement du
  modèle, pas la génération. `load_duration` le distingue.
- Si la pression mémoire passe au rouge avec le 4B, ce n'est pas un incident
  à contourner : c'est le résultat de la mesure, et il désigne le 2B.

## Rapport créateur

*À remplir.*

## Rapport vérificateur

*À remplir.*

| Contrôle | Résultat | Preuve |
|---|---|---|
| Réponse produite hors ligne | | |
| Historique après reboot | | |
| Modèle affiché | | |
| TTFT / tok/s (4B) | | |
| TTFT / tok/s (2B) | | |
| Pression mémoire (4B) | | |

Verdict :

## Décision attendue de Kevin

Confirmer le modèle par défaut au vu des mesures : `qwen3.5:4b-q4_K_M` reste
principal, ou le `2b` prend sa place en déplacement (décision D-004).
