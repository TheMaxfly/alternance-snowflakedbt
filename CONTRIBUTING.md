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
- Exceptions documentees sur ce depot :
  - `B101` ignore pour les tests `pytest`
  - `B608` ignore car le projet orchestre nativement beaucoup de SQL Snowflake
    en chaine de caracteres, ce qui genere des faux positifs Bandit

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
- Exception documentee sur ce depot :
  - `python-semantic-release` n'est pas installe dans l'environnement `uv`
    principal car il entre en conflit avec `dbt-core` sur la dependance
    `click`
  - l'outil reste la reference pour la release, mais doit etre execute dans un
    environnement isole si active plus tard

## Documentation

- `mkdocs`
- `mkdocs-material`
- `mkdocstrings[python]`

## CI/CD

- Le depot doit exposer un workflow `.github/workflows/ci.yml`
- Le pipeline CI de reference couvre :
  - lint
  - format check
  - typecheck
  - security scan
  - audit des dependances non bloquant
  - tests
  - verification `pre-commit`

## Application Rule

Cette convention est la reference par defaut du depot.

Si un projet ne peut pas appliquer une partie de cette stack, l'ecart doit etre :

- explique
- documente
- limite au strict necessaire
