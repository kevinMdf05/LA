# reports/ — sorties de mission

Les rapports produits ici décrivent **la machine de Kevin**. Ils sont ignorés
par Git (`.gitignore`) : un rapport matériel ou de diagnostic n'a pas à
partir sur GitHub sans relecture.

| Fichier | Produit par |
|---|---|
| `hardware-report.json` / `.md` | `make hardware` |
| `models-installed.md` | `make preload` |
| `versions-installed.md` | `make versions` |
| `offline-test-*.md` | `make offline-test` |
| `diagnose-*.md` | `make diagnose` |

Aucun ne contient de secret : les scripts le vérifient et refusent d'écrire
un rapport contenant une clé.
