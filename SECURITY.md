# SECURITY — clés, réseau, appareil, menaces

Référence : KAI-MISSION-001 §9. Ce document décrit ce qui est **appliqué**,
et distingue explicitement ce qui est **écrit mais pas encore appliqué par un
mécanisme**.

---

## 1. Clés API (§9.1)

Règles absolues :

- **Jamais** dans le JavaScript livré au navigateur.
- **Jamais** dans Git, une capture d'écran, un journal ou un export de
  conversation.
- Stockage prioritaire dans le **trousseau macOS** ; à défaut, `.env` local
  avec permissions `600`, exclu de Git.
- Seul le processus serveur lit les secrets.
- Masquage dans l'interface, rotation possible, une clé et un budget par
  fournisseur.

État V0 : **aucune clé n'existe.** `KAI_CLOUD_BUDGET_EUR=0`, aucune variable
de clé renseignée. Ce n'est pas un contrôle sophistiqué, c'est le contrôle le
plus fiable disponible : il n'y a rien à fuiter.

Vérification : `make secret-scan` — cherche des motifs de clés (`sk-`,
`sk-ant-`, `AIza`, jetons GitHub, clés privées PEM) dans **l'arbre de travail
et dans tout l'historique Git**, et vérifie que `.env` est bien ignoré.
À lancer avant chaque commit.

Si une clé a été committée : la **révoquer chez le fournisseur d'abord.**
Réécrire l'historique ensuite ne la désactive pas — une clé poussée sur GitHub
doit être considérée comme compromise, même une seconde.

---

## 2. Réseau (§9.2)

| Règle | Application V0 |
|---|---|
| Services liés à `127.0.0.1` | ✅ `KAI_BIND_HOST=127.0.0.1` ; Ollama et Open WebUI |
| Aucun port sur `0.0.0.0` sans décision explicite | ✅ décision D-002 ; ouverture = question Q-002 |
| Authentification locale si joignable sur le LAN | ✅ `WEBUI_AUTH=true` par défaut |
| CORS limité aux origines locales | ✅ pas d'origine distante configurée |
| Aucune télémétrie facultative | ✅ `SCARF_NO_ANALYTICS`, `DO_NOT_TRACK`, `ANONYMIZED_TELEMETRY=false` |
| Aucun tunnel public | ✅ aucun ngrok / Cloudflare Tunnel / port forwarding |

`make status` affiche les interfaces réellement en écoute. Si une ligne
montre `0.0.0.0` ou `*`, c'est une anomalie à traiter avant toute utilisation
hors du domicile.

---

## 3. Appareil et données (§9.3)

À la charge de Kevin, sur le Mac :

- **FileVault activé.** Sans lui, le vol du Mac donne accès aux documents
  personnels indexés et à `.env` en clair. C'est la protection la plus
  rentable de toute cette liste.
- **Verrouillage automatique de session** après quelques minutes.
- **Sauvegarde chiffrée** — voir `make backup`, et la note ci-dessous.

Côté logiciel :

- Les contenus récupérés (documents, Web) sont des **données, jamais des
  instructions système** (§9.3). Un PDF qui contient « ignore les consignes
  précédentes » est un texte à citer, pas un ordre à suivre.
- Les outils à effet externe exigent une confirmation humaine.

> **Limite honnête de la V0 :** cette séparation instructions/données est
> assurée par Open WebUI tel quel. Nous ne l'avons pas durcie et nous ne
> l'avons pas testée. La question piège `rag-018` du jeu d'évaluation existe
> précisément pour mesurer si elle tient. Tant qu'elle n'a pas tourné,
> R-009 est un risque **ouvert**.

---

## 4. Modèle de menace minimal (§9.4)

| Menace | Vraisemblance | Impact | Ce qui la réduit aujourd'hui |
|---|---|---|---|
| Vol du Mac | Moyenne | **Critique** — documents + `.env` | FileVault (à activer par Kevin), verrouillage session |
| Malware local | Faible | Critique | Aucune protection spécifique ; le système hérite de la sécurité de macOS |
| Clé committée dans Git | Moyenne | **Critique** | `.gitignore`, `make secret-scan`, aucune clé en V0 |
| Serveur exposé au LAN | Faible | Élevé | Liaison `127.0.0.1` (D-002), `WEBUI_AUTH` |
| Document malveillant ingéré | Moyenne | Élevé | Contrôle de type MIME réel, rejet des exécutables/archives |
| Injection de prompt (RAG ou Web) | **Élevée** | Élevé | Consigne de séparation ; **non testé** → R-009 |
| Dépendance compromise | Faible | Élevé | Versions épinglées + `requirements.lock` (R-006) |
| Sauvegarde non chiffrée | Moyenne | Élevé | `make backup` exclut les secrets ; chiffrement **optionnel** → à activer |
| Fournisseur cloud recevant des données privées | Moyenne | **Critique** | `local_only` par défaut, budget à 0, aucune clé (D-005, D-006) |

Les deux menaces les moins couvertes aujourd'hui sont **l'injection de
prompt** et **le malware local**. La première est mesurable et le sera ; la
seconde sort du périmètre de ce projet.

---

## 5. Sauvegardes

`make backup` produit une archive horodatée des données persistantes avec un
`SHA256SUMS`, et **exclut `.env`** : une sauvegarde ne doit pas transporter
les secrets (§12 KAI-EXEC-006).

Conséquence à connaître : **restaurer une sauvegarde ne restaure pas les
clés.** C'est voulu. Les clés se reconfigurent depuis le trousseau.

Pour une archive chiffrée : `make backup ENCRYPT=1` (chiffrement symétrique
GPG, phrase de passe demandée interactivement, jamais stockée).

Une sauvegarde n'a de valeur que restaurée : `make restore` restaure **vers
un dossier temporaire** par défaut, jamais par-dessus les données vivantes
(R-010).

---

## 6. Vérifications de sécurité à rejouer (§14)

```sh
make secret-scan     # secrets dans l'arbre et l'historique
make status          # interfaces réellement en écoute
ls -l .env           # doit afficher -rw------- (600)
```

Contrôles manuels restants, à faire une fois la V0 lancée :

- Inspecter le bundle JavaScript servi par Open WebUI et y chercher toute
  chaîne ressemblant à une clé.
- Tenter l'import d'un type de fichier interdit et d'un fichier surdimensionné.
- Confirmer qu'une collection `local_only` n'est jamais envoyée au cloud.
