# Contributing

Ce depot utilise une stack d'outillage par defaut qui doit etre appliquee a tous les projets, sauf incompatibilite technique explicite.

## Package Management

- Utiliser `uv` partout :
  - installation des dependances
  - execution locale
  - CI

## Code Quality

- `ruff` pour le lint et le format
- Remplace `flake8`, `isort` et `black`
- Regles attendues :
  - `E`
  - `W`
  - `F`
  - `I`
  - `B`
  - `C4`
  - `UP`
- Longueur de ligne : `88`

- `pyright` pour le typage
- Mode attendu : `basic`

## Security

- `bandit` pour l'analyse statique de securite du code source
- `pip-audit` pour l'audit des vulnerabilites des dependances
- `pip-audit` est non bloquant par defaut

## Testing

- `pytest` pour les tests unitaires
- `pytest-cov` pour la couverture et la generation XML
- Tests d'integration contre API reelle avec service local lance via `uvicorn`
- `locust` pour les tests de charge

## Pre-commit

Le depot doit utiliser `pre-commit` avec au minimum :

- `trailing-whitespace`
- `end-of-file-fixer`
- `check-yaml`
- `check-added-large-files`
- `detect-private-key`
- `check-merge-conflict`
- `ruff`

## Versioning And Release

- `python-semantic-release`
- Bump automatique via commits conventionnels
- Generation de `CHANGELOG.md`
- Publication GitHub Release

## Documentation

- `mkdocs`
- `mkdocs-material`
- `mkdocstrings[python]`

## Application Rule

Cette convention est la reference par defaut du depot.

Si un projet ne peut pas appliquer une partie de cette stack, l'ecart doit etre :

- explique
- documente
- limite au strict necessaire
