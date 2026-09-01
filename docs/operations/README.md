# Exploitation

## Au quotidien

| Besoin | Commande |
|---|---|
| Démarrer | `make start` |
| Arrêter | `make stop` |
| État | `make status` |
| Sauvegarder | `make backup` |
| Diagnostiquer | `make diagnose` |

## Avant un vol

```sh
make flight-check
```

Enchaîne le scan de secrets, l'état des services et le test hors ligne. Puis
**le test à froid manuel** décrit dans [`../../OFFLINE_RUNBOOK.md`](../../OFFLINE_RUNBOOK.md),
section A — celui-là ne s'automatise pas.

## Quand quelque chose ne va pas

1. `make status` — les services répondent-ils, et sur quelles interfaces ?
2. `make diagnose` — rapport complet, sans secret, partageable.
3. `logs/ollama.log` et `logs/webui.log` — les 30 dernières lignes suffisent
   presque toujours.
4. Consigner dans [`../../ANOMALIES.md`](../../ANOMALIES.md) — surtout si
   c'est arrivé en vol, tant que c'est frais.

## Signaux à surveiller sur 8 Go

| Signal | Où | Réaction |
|---|---|---|
| Pression mémoire jaune ou rouge | Moniteur d'activité | Fermer VS Code, Docker, Claude Code |
| Swap qui grimpe | `make status` | Passer au modèle `2b` |
| TTFT > 30 s | `make eval` | Modèle trop lourd pour l'état actuel de la machine |
| Disque < 15 Go libres | `make status` | Faire du ménage avant d'ingérer ou de télécharger |
