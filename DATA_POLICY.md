# DATA_POLICY — données, collections, sensibilité, envoi au cloud

Référence : KAI-MISSION-001 §6 et §7.

---

## 1. Principe

**Par défaut, une donnée de Kevin ne quitte pas le Mac.** Toute exception est
une décision explicite, prise collection par collection, pas un réglage global.

Un envoi au cloud est **irréversible** : une fois un passage transmis à un
fournisseur, on ne peut plus le reprendre. C'est la raison du défaut
restrictif, et la raison pour laquelle il n'y a pas de « mode pratique » qui
lève la règle d'un coup.

---

## 2. Collections

Structure de départ (§6.4). **Aucune collection n'est créée automatiquement** :
elles n'existent qu'à la demande de Kevin (question ouverte Q-005).

| Collection | Contenu prévu | Sensibilité par défaut | Portée |
|---|---|---|---|
| `personal` | Documents personnels | `private` | `local_only` |
| `travel-offline` | Billets, itinéraires, guides pour le vol | `private` | `local_only` |
| `entertainment` | Lectures, films, musique | `internal` | `local_only` |
| `learning` | Cours, documentation, apprentissage | `internal` | `local_only` |
| `notes` | Notes personnelles | `private` | `local_only` |
| `reference-general` | Références générales non sensibles | `public` | `cloud_with_confirmation` |

> **Interdiction explicite (§6.4).** Aucun projet professionnel, immobilier ou
> d'entreprise ne doit être importé, mentionné ou connecté automatiquement.
> Ces collections sont personnelles. Si un tel document apparaît dans un
> dossier à ingérer, il est écarté et signalé, pas indexé « au cas où ».

---

## 3. Niveaux de sensibilité

| Niveau | Signification |
|---|---|
| `private` | Donnée personnelle. **Défaut de tout document importé.** |
| `internal` | Personnelle mais sans enjeu si divulguée |
| `public` | Déjà publique par nature |

**Règle d'attribution : le défaut est `private`.** Un document n'est jamais
promu à `internal` ou `public` automatiquement, ni par déduction sur son
contenu, ni parce qu'il « a l'air » anodin.

---

## 4. Politique d'envoi au cloud (§6.5)

| Portée | Comportement |
|---|---|
| `local_only` | Ne quitte jamais l'appareil. Le modèle local répond, ou le système explique qu'il ne peut pas. |
| `cloud_with_confirmation` | Demande explicite **avant chaque envoi**, avec la liste des passages concernés et le fournisseur destinataire. |
| `cloud_allowed` | Utilisable par les modèles cloud sélectionnés, sans confirmation par requête. |

Une confirmation vaut **pour un envoi**, pas pour la session. « Autoriser une
fois » ne doit jamais devenir « autoriser toujours » par accumulation.

### Ce qui applique réellement cette politique aujourd'hui

Distinction importante, à ne pas confondre :

- **En V0 :** ce qui empêche une fuite, c'est qu'**il n'y a aucune clé API**
  et que `KAI_CLOUD_BUDGET_EUR=0`. Il n'existe pas de portail technique par
  collection. Open WebUI ne connaît pas nos étiquettes de sensibilité.
  → Conséquence directe : **tant que la V0 est en service, ne pas ajouter de
  clé API et utiliser des documents privés en même temps** sans avoir lu
  KAI-EXEC-005.
- **En V1 :** le portail de politique est un composant du routeur, entre le
  RAG et la passerelle cloud. C'est lui qui refuse matériellement l'envoi
  d'un passage `local_only`. C'est un livrable de KAI-EXEC-007.

Ne pas se raconter que la politique est appliquée avant que ce composant
existe. Le risque R-004 reste ouvert jusque-là.

---

## 5. Métadonnées minimales par fragment (§6.2)

Tout fragment indexé porte :

`document_id`, `sha256`, `filename`, `collection`, `source_type`,
`created_at`, `document_date`, `language`, `page`, `section`, `chunk_index`,
`sensitivity`, `owner`, `parser_version`, `embedding_model`,
`embedding_version`.

`page` et `section` ne sont pas décoratifs : **sans eux, pas de citation
vérifiable**, et R-005 (citations fausses) devient indétectable.

`embedding_model` et `embedding_version` non plus : le jour où le modèle
d'embeddings change, les anciens vecteurs deviennent incomparables aux
nouveaux. Ces deux champs disent quels fragments réindexer.

---

## 6. Pipeline d'ingestion (§6.1)

1. Copier le fichier dans une zone d'entrée immuable.
2. Calculer le SHA-256 ; bloquer les doublons exacts.
3. Détecter le **type MIME réel**, pas l'extension.
4. Rejeter exécutables et archives dangereuses.
5. Extraire le contenu (Docling) ; OCR **uniquement si nécessaire**.
6. Conserver la structure : titre, pages, sections, tableaux, date, source.
7. Nettoyer sans détruire ce qui permet la citation.
8. Découper selon la structure, chevauchement limité.
9. Produire les embeddings **localement**.
10. Stocker vecteurs et métadonnées.
11. Indexer aussi le texte pour BM25.
12. Contrôle qualité, et **affichage des erreurs d'ingestion** — un document
    qui a échoué silencieusement est pire qu'un document absent.

---

## 7. Mémoire personnelle (§7)

Quatre couches **séparées**, jamais mélangées :

| Couche | Contenu | Réinjection |
|---|---|---|
| Profil approuvé | Préférences stables validées par Kevin | Sur pertinence |
| Mémoire de projet | Décisions, contraintes, statuts, prochaines actions | Sur pertinence |
| Mémoire épisodique | Résumés de conversations, datés et sourcés | Sur pertinence |
| Historique brut | Conversations complètes | **Jamais automatiquement** |

Chaque souvenir porte : source, date, confiance, portée, sensibilité,
expiration éventuelle, statut `proposé` / `approuvé` / `rejeté`.

Règles impératives :

- Ne **jamais** déduire silencieusement un fait sensible.
- Afficher **pourquoi** un souvenir a été utilisé.
- Permettre modification et suppression.
- Ne pas réinjecter toute la mémoire à chaque requête — récupérer seulement
  ce qui est pertinent.
- Ne jamais confondre **une hypothèse du modèle** et **un fait déclaré par
  Kevin**. Ce sont deux statuts différents, et le second seul fait autorité.

État : la mémoire contrôlable est un livrable **V1**. En V0, il n'y a que
l'historique de conversation d'Open WebUI, qui n'est pas une mémoire au sens
ci-dessus et ne doit pas être présenté comme telle.

---

## 8. Export et effacement

Kevin doit pouvoir, à tout moment :

- exporter conversations, mémoires, réglages et index (§2.2) ;
- supprimer une collection entière, vecteurs et métadonnées compris ;
- supprimer un souvenir individuel.

Supprimer un document de `data/` ne suffit pas : ses vecteurs et ses
fragments survivent dans l'index. La suppression doit passer par la commande
de désindexation, sinon le document continue d'être cité alors qu'il est
censé avoir disparu.
