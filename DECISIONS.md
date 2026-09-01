# DECISIONS — journal des décisions

Deux sections. **A** : décisions appliquées par défaut, conformes à la
recommandation du plan directeur ; Claude a avancé sans bloquer, comme le §17
l'autorise. **B** : décisions **structurantes ou irréversibles** qui restent
ouvertes tant que Kevin n'a pas tranché.

Format : identifiant, date, statut, décision, justification, réversibilité.

---

## A. Décisions appliquées par défaut

### D-001 — Appareil serveur : le Mac M1, pas l'iPhone
**2026-09-01 · APPLIQUÉ · conforme §17**
Le modèle tourne sur le Mac. L'iPhone peut au mieux être un client navigateur
sur le même réseau — et cet accès est **désactivé par défaut** (voir D-002).
*Réversible :* oui, sans coût.

### D-002 — Écoute sur `127.0.0.1` uniquement
**2026-09-01 · APPLIQUÉ · conforme §9.2**
Ollama et Open WebUI sont liés à la boucle locale. Rien n'écoute sur
`0.0.0.0`, aucun tunnel public. Conséquence assumée : **le service n'est pas
joignable depuis l'iPhone ou l'iPad.** Si Kevin veut cet accès, c'est une
décision explicite (→ Q-002), qui impose d'abord l'authentification locale.
*Réversible :* oui, mais élargit la surface d'attaque — d'où le passage par
une question ouverte.

### D-003 — V0 = Open WebUI + Ollama, sans personnalisation de marque
**2026-09-01 · APPLIQUÉ · conforme §17**
On assemble de l'existant, on n'écrit pas de code d'interface pour la V0.
La licence Open WebUI interdit de retirer ou remplacer sa marque
(voir `VERSIONS.md`) : la V0 restera visiblement « Open WebUI ». Le nom
« Kevin AI » appartient à la V1, qui est une interface distincte.
*Réversible :* oui — la V1 remplace la V0 sans la casser.

### D-004 — Modèles : `qwen3.5:4b-q4_K_M` principal, `2b-q4_K_M` secours
**2026-09-01 · APPLIQUÉ SOUS RÉSERVE DE MESURE · conforme §5**
Le 4B est le *candidat* qualité, pas le choix définitif. Le 2B garantit la
continuité si le 4B provoque du swap, de la chauffe ou une latence excessive.
**La décision n'est confirmée qu'après le benchmark** (`make eval`) :
mesurer, pas supposer.
*Réversible :* oui — changer un tag dans `.env`.

### D-005 — Aucune clé API tant que la V0 n'est pas validée
**2026-09-01 · APPLIQUÉ · conforme §12 KAI-EXEC-005**
`KAI_CLOUD_BUDGET_EUR=0` par défaut : aucun appel payant possible. Les
fournisseurs sont branchés **un par un**, après la V0.
*Réversible :* oui.

### D-006 — Toutes les données personnelles en `local_only`
**2026-09-01 · APPLIQUÉ · conforme §6.5**
Sensibilité par défaut : `private`, portée `local_only`. Aucun passage au
cloud sans changement de politique explicite, collection par collection.
*Réversible :* oui, mais **l'envoi d'un document au cloud est irréversible**
une fois fait — d'où le défaut restrictif.

### D-007 — Installation native plutôt que Docker sur cette machine
**2026-09-01 · APPLIQUÉ · conforme §5**
Ollama natif macOS (accès direct à Apple Silicon) + Open WebUI dans un venv
`uv`. Docker Desktop ajoute une VM Linux et plusieurs Go de mémoire résidente,
ce qui n'est pas défendable sur 8 Go. `infra/compose/docker-compose.yml` est
livré comme **chemin alternatif documenté**, pas comme chemin recommandé.
*Réversible :* oui.

### D-008 — Contexte initial 4096 tokens
**2026-09-01 · APPLIQUÉ · conforme §5, R-008**
Malgré les 256K annoncés par le modèle. Passage à 8192 **seulement** après
mesure mémoire concluante.
*Réversible :* oui.

### D-009 — Reranker, OCR, Whisper et TTS exclus de la V0
**2026-09-01 · APPLIQUÉ · conforme §12 KAI-EXEC-004**
Chacun consomme de la mémoire pendant une conversation. Aucun n'est requis
pour « chat + RAG + historique hors ligne ». Ne pas les ajouter avant que la
V0 vole (R-011).
*Réversible :* oui, après mesure de marge.

### D-010 — La V1 n'est pas commencée
**2026-09-01 · APPLIQUÉ · conforme §12 KAI-EXEC-007**
`apps/` et `services/` ne contiennent que de la conception. Écrire le backend
V1 maintenant consommerait le temps qui doit aller à faire voler la V0.
*Réversible :* sans objet.

---

## B. Questions ouvertes — décision de Kevin requise

Aucune de ces questions ne bloque `make hardware`, `make install` ou
`make preload`. Elles bloquent ce qui vient après.

### Q-001 — Espace disque réellement mobilisable
**BLOQUE : `make preload` (téléchargement de 5,64 Go)**
Il faut ≈ 5,64 Go de modèles **plus** 15 à 20 Go de marge libre après
téléchargement, pour le swap, les caches et macOS (§5, §15). `make hardware`
mesure l'espace libre ; **Kevin valide** que cette place est mobilisable.
*Réponse attendue :* oui / non / après ménage.

### Q-002 — Appareils depuis lesquels Kevin veut accéder au service
**BLOQUE : toute ouverture réseau au-delà de `127.0.0.1`**
Aujourd'hui : le Mac uniquement. Si l'iPhone ou l'iPad doivent y accéder sur
le réseau local, il faut lier le service au LAN — ce qui rend
l'authentification locale et un pare-feu **obligatoires**, pas optionnels.
*Réponse attendue :* Mac seul / Mac + appareils du foyer.

### Q-003 — Fournisseurs API déjà possédés
**BLOQUE : KAI-EXEC-005**
Quelles clés Kevin possède-t-il déjà (OpenAI, Anthropic, Google, autre) ?
Un seul fournisseur est branché en premier. Aucun quota gratuit n'est
considéré comme garanti (§4.2).
*Réponse attendue :* liste des fournisseurs, et lequel brancher en premier.

### Q-004 — Niveau de batterie et durée de vol acceptables
**BLOQUE : la clôture de KAI-EXEC-001**
Faire tourner un LLM localement consomme de la batterie et chauffe. Combien
de temps Kevin veut-il pouvoir l'utiliser en vol, sur batterie ? La réponse
détermine si le 4B est tenable ou si le 2B doit devenir le modèle par défaut
en déplacement.
*Réponse attendue :* durée cible en minutes.

### Q-005 — Contenu réel des collections
**BLOQUE : KAI-EXEC-003**
Les six collections (§6.4) sont une structure de départ vide. Elles ne sont
créées **qu'à la demande de Kevin**, et **aucun** projet professionnel,
immobilier ou d'entreprise ne doit être importé ou connecté.
*Réponse attendue :* quelles collections créer, et quels dossiers ingérer.

### Q-006 — Suppression définitive du site vitrine L.A.
**BLOQUE : rien — signalé par prudence**
Ce dépôt contenait un site Next.js « L.A. travel » sans rapport avec KAI.
Il a été retiré de l'arbre sur la branche KAI, comme demandé. **Il reste
présent dans l'historique Git et sur la branche
`claude/la-travel-premium-site-TxTnS`** — c'est-à-dire récupérable.
Claude n'a **pas** supprimé le dépôt GitHub ni réécrit l'historique : cette
partie-là serait irréversible, et le §19 interdit d'effacer une donnée
existante sans identification précise et accord.
*Réponse attendue :* garder l'historique / supprimer aussi l'ancienne branche.
