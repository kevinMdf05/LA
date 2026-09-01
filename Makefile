# ---------------------------------------------------------------------------
# KAI — commandes d'exploitation.
#
# Toutes les cibles s'exécutent sur le Mac de Kevin.  Aucune ne télécharge
# quoi que ce soit sans l'annoncer, aucune ne détruit de données.
# ---------------------------------------------------------------------------

SHELL := /bin/bash
.DEFAULT_GOAL := help

ARCHIVE ?=
IN_PLACE ?= 0
ENCRYPT ?= 0

.PHONY: help hardware install preload start stop restart status \
        backup restore offline-test diagnose secret-scan versions \
        eval test flight-check

help: ## Affiche cette aide
	@printf '\nKAI — IA personnelle hybride de Kevin\n\n'
	@printf 'Parcours normal :\n'
	@printf '  1. make hardware      audit matériel (lecture seule)\n'
	@printf '  2. make install       Ollama + Open WebUI épinglé\n'
	@printf '  3. make preload       modèles locaux (≈ 5,64 Go, confirmation demandée)\n'
	@printf '  4. make start         lance KAI sur http://127.0.0.1:8080\n'
	@printf '  5. make offline-test  AVANT LE VOL\n\n'
	@printf 'Toutes les cibles :\n\n'
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
	@printf '\n'

hardware: ## KAI-EXEC-001 — audit matériel, non destructif
	@./scripts/hardware-report.sh

install: ## KAI-EXEC-002 — installe Open WebUI épinglé dans .venv
	@./scripts/install-v0.sh

preload: ## KAI-EXEC-002 — télécharge les modèles épinglés (annonce la taille)
	@./scripts/preload-models.sh

start: ## Démarre Ollama et Open WebUI sur 127.0.0.1
	@./scripts/start.sh

stop: ## Arrête les services lancés par KAI
	@./scripts/stop.sh

restart: stop start ## Redémarre KAI

status: ## État des services, modèles, réseau et ressources
	@./scripts/status.sh

backup: ## KAI-EXEC-006 — sauvegarde (ENCRYPT=1 pour chiffrer)
	@ENCRYPT=$(ENCRYPT) ./scripts/backup.sh

restore: ## Restaure une sauvegarde (ARCHIVE=... [IN_PLACE=1])
	@if [ -z "$(ARCHIVE)" ]; then \
	  ./scripts/restore.sh; \
	elif [ "$(IN_PLACE)" = "1" ]; then \
	  ./scripts/restore.sh "$(ARCHIVE)" --in-place; \
	else \
	  ./scripts/restore.sh "$(ARCHIVE)"; \
	fi

offline-test: ## KAI-EXEC-004 — vérifie l'aptitude au vol
	@./scripts/offline-test.sh

diagnose: ## Rapport de diagnostic complet, sans secret
	@./scripts/diagnose.sh

secret-scan: ## Cherche des secrets dans l'arbre ET l'historique Git
	@./scripts/secret-scan.sh

versions: ## Relève les versions réellement installées (anomalie A-001)
	@./scripts/check-versions.sh

eval: ## Lance le jeu d'évaluation des modèles (§14)
	@python3 tests/evaluation/run_eval.py

test: ## Tests d'intégration du dépôt (syntaxe, cohérence, sécurité)
	@./tests/integration/test_repo.sh

flight-check: secret-scan status offline-test ## Contrôle complet avant le vol
	@printf '\nContrôle avant vol terminé. Le test à froid reste manuel :\n'
	@printf 'voir OFFLINE_RUNBOOK.md, section A.\n\n'
