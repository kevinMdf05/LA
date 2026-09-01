# ANOMALIES — anomalies ouvertes et registre des risques

## 1. Anomalies ouvertes

Statuts : `OUVERTE`, `CONTOURNÉE`, `FERMÉE`.

### A-001 — Versions Ollama et `uv` non relevées
**OUVERTE · 2026-09-01 · gravité : faible**

*Constat.* `VERSIONS.md` devait épingler la version d'Ollama et de `uv`. Les
deux se relèvent sur l'API GitHub, qui répond `403 Forbidden` depuis
l'environnement d'exécution de Claude (proxy sortant).

*Impact.* Deux lignes de `VERSIONS.md` sont en « À ÉPINGLER » au lieu de
« VÉRIFIÉ ». Aucun impact fonctionnel : ces versions doivent de toute façon
être relevées **sur le Mac**, puisque c'est là qu'elles s'installent (§4.1).

*Contournement.* `scripts/check-versions.sh` relève les versions réellement
installées et les écrit dans `reports/versions-installed.md`.

*Fermeture.* Reporter les valeurs dans `VERSIONS.md` après `make install`.

---

### A-002 — Aucune mesure matérielle réelle n'a été produite
**OUVERTE · 2026-09-01 · gravité : structurante**

*Constat.* Le plan directeur exige un `hardware-report.json`, un benchmark
mémoire, des mesures de tokens/seconde, de température et de batterie, et un
test à froid en mode avion. Claude s'exécute dans un conteneur **Linux
distant**. La machine à mesurer est le **Mac M1 de Kevin**.

*Impact.* Il serait faux de présenter une quelconque mission KAI-EXEC-001 à
006 comme « VALIDÉE TECHNIQUEMENT ». Les valeurs de `hardware-report.json`
n'existent pas encore ; aucune n'a été inventée pour combler le vide.

*Contournement.* Les scripts qui produisent ces mesures sont livrés et
vérifiables ; leur syntaxe et leur logique de secours sont testées. Les
statuts de mission restent à `PLANIFIÉ`.

*Fermeture.* Après `make hardware`, `make preload` et `make eval` sur le Mac.

---

### A-003 — Le tag `qwen3.5:4b` par défaut est déjà en Q4_K_M
**CONTOURNÉE · 2026-09-01 · gravité : faible**

*Constat.* `qwen3.5:4b` et `qwen3.5:4b-q4_K_M` pèsent tous deux 3,4 Go : le
tag par défaut *est* aujourd'hui la quantification Q4_K_M.

*Impact.* Aucun aujourd'hui. Mais un tag par défaut peut être re-pointé en
amont sans prévenir — c'est exactement le risque R-006.

*Contournement.* On épingle partout le tag explicite `qwen3.5:4b-q4_K_M`, y
compris là où le tag court suffirait.

---

### A-004 — Licence Open WebUI : restriction de marque
**OUVERTE · 2026-09-01 · gravité : moyenne (juridique, pas technique)**

*Constat.* Open WebUI n'est pas sous licence libre standard. Sa licence
interdit d'altérer, retirer, masquer ou remplacer la marque « Open WebUI »,
sauf cas limités.

*Impact.* Aucun pour un usage personnel et local. Mais l'idée de « repeindre »
la V0 aux couleurs de « Kevin AI » n'est pas ouverte, et une éventuelle
redistribution serait à examiner.

*Contournement.* La V0 reste affichée comme Open WebUI (décision D-003). La
V1 est une interface distincte, écrite par nous.

*Fermeture.* Lecture du texte de licence par Kevin avant toute personnalisation
visuelle de la V0.

---

### A-005 — Le scan de secrets laissait passer les clés modernes
**FERMÉE · 2026-09-01 · gravité : élevée (au moment de la découverte)**

*Constat.* Découverte en testant le scanner **contre une vraie forme de clé**
plutôt qu'en le lançant sur un dépôt propre. Le motif `sk-[A-Za-z0-9]{20,}`
exige des caractères alphanumériques immédiatement après `sk-`. Or une clé
OpenAI actuelle s'écrit `sk-proj-…` et une clé Anthropic `sk-ant-api03-…` :
le tiret arrive au cinquième caractère, et le motif ne correspond jamais.

*Impact.* `make secret-scan` renvoyait « aucun secret détecté » sur un dépôt
contenant une clé OpenAI en clair. Le contrôle censé protéger du risque R-003
était inopérant contre le format de clé le plus courant.

*Correction.* Motif élargi à `sk-[A-Za-z0-9_-]{20,}`, qui couvre aussi les
clés Anthropic ; ajout du format GitLab `glpat-`.

*Revérification.* Quatre formes réelles plantées dans un fichier suivi
(OpenAI `sk-proj-`, Anthropic `sk-ant-api03-`, Google `AIza`, GitHub `ghp_`) :
les quatre sont désormais détectées, et le dépôt redevient propre après
retrait.

*Leçon retenue.* Un contrôle de sécurité qui n'a jamais rien trouvé n'est pas
une preuve que le dépôt est propre — c'est peut-être seulement la preuve que
le contrôle ne fonctionne pas. Tout contrôle de ce type doit être testé
contre un cas positif fabriqué avant qu'on lui fasse confiance.

## 2. Registre des risques (§16)

Reproduit du plan directeur, complété d'une colonne « état » et du test
réellement livré dans ce dépôt.

| ID | Risque | Gravité | Prévention | Test livré | État |
|---|---|---|---|---|---|
| R-001 | Modèle trop lourd, système inutilisable | Haute | Profil matériel + benchmark | `make hardware`, `make eval` (charge 10 min) | Prévention en place, **non mesuré** |
| R-002 | RAG cassé hors ligne car embedding absent | **Critique** | Préchargement + démarrage à froid | `make offline-test`, `OFFLINE_RUNBOOK.md` | Prévention en place, **non mesuré** |
| R-003 | Clé API exposée dans le navigateur / Git | **Critique** | Secrets côté serveur + scan | `make secret-scan` | ✅ Scan exécuté, dépôt propre |
| R-004 | Documents privés envoyés au cloud | **Critique** | Étiquettes + politique | `DATA_POLICY.md`, budget cloud à 0 | Politique en place, **portail non implémenté** (V1) |
| R-005 | Citations fausses | Haute | Métadonnées page/section | `tests/evaluation/rag_questions.jsonl` | Corpus de questions livré, **non exécuté** |
| R-006 | Dépendance à une version flottante | Moyenne | Versions et digests épinglés | `make versions`, `requirements.lock` | ✅ Aucun `latest` en livraison |
| R-007 | Fonctionne, mais pas après redémarrage | Haute | Runbook + procédure de démarrage | `make offline-test` + test à froid manuel | Procédure écrite, **non mesuré** |
| R-008 | Contexte trop grand, manque de mémoire | Haute | Contexte progressif 4K → 8K | `KAI_NUM_CTX=4096`, mesure RAM dans `make eval` | ✅ Défaut prudent appliqué |
| R-009 | Injection de prompt via document ou Web | Haute | Séparation instructions / données | Question piège `rag-018` | Question livrée, **non exécutée** |
| R-010 | Sauvegarde inutilisable | Haute | Restauration réelle | `make restore` vers dossier temporaire + checksum | Script livré, **non exécuté sur données réelles** |
| R-011 | Trop de composants avant le vol | Haute | V0 prioritaire, V1 gelée | Décisions D-009, D-010 | ✅ Appliqué |
| R-012 | Données incohérentes ou obsolètes | Moyenne | Dates, versions, provenance | Questions `rag-003`, `rag-012` | Questions livrées, **non exécutées** |

**Lecture honnête de ce tableau :** sur douze risques, quatre sont
effectivement traités aujourd'hui (R-003, R-006, R-008, R-011). Les huit
autres ont une prévention conçue et un test écrit, mais **aucune preuve
d'exécution**. C'est la conséquence directe de A-002.
