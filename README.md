# Pipeline NYC Yellow Taxi — Snowflake

Pipeline de données pour l'analyse des trajets Yellow Taxi de New York City
(2025 + début 2026), construit avec Snowflake, Python, dbt et Evidence.

## Architecture

```text
Fichiers Parquet (local ou TLC)
        │
        ▼  PUT (stage interne Snowflake)
┌──────────────────────────────────────┐
│ RAW.yellow_taxi_trips               │  55.8M lignes — données brutes
└───────────────────┬──────────────────┘
                    ▼  dbt staging
┌──────────────────────────────────────┐
│ STAGING.stg_yellow_taxi_trips       │  données nettoyées
└───────────────────┬──────────────────┘
                    ▼  dbt intermediate
┌──────────────────────────────────────┐
│ STAGING.int_trip_metrics            │  données enrichies
└───────────────────┬──────────────────┘
                    ▼  dbt marts
┌─────────────────────────────────────────────────────────────┐
│ FINAL.fact_trips       │ table de faits détaillée          │
│ FINAL.daily_summary    │ 429 lignes (1/jour)               │
│ FINAL.zone_analysis    │ 262 zones de pickup               │
│ FINAL.hourly_patterns  │ 168 patterns (24h × 7j)           │
└─────────────────────────────────────────────────────────────┘
```

## Source des données

- **Source** : NYC Taxi & Limousine Commission
- **URL** : https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
- **Format** : Parquet (compressé Snappy)
- **Période** : Janvier 2025 → Février 2026 (14 fichiers mensuels)
- **Volume** : ~55.8 millions de trajets

## Infrastructure Snowflake

| Ressource | Nom |
|-----------|-----|
| Warehouse | `NYC_TAXI_WH` (MEDIUM, auto-suspend 60s) |
| Database | `NYC_TAXI_DB` |
| Schémas | `RAW`, `STAGING`, `FINAL` |
| Stage | `RAW.TAXI_INT_STAGE` (interne) |
| File format | `RAW.TAXI_PARQUET_FF` (Parquet) |

### Création automatique de la table RAW

La table `RAW.yellow_taxi_trips` est créée automatiquement via
`INFER_SCHEMA` + `CREATE TABLE USING TEMPLATE`. Les colonnes et types sont
détectés directement depuis le fichier Parquet, sans définition manuelle.

```sql
CREATE TABLE RAW.yellow_taxi_trips
    USING TEMPLATE (
        SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
        FROM TABLE(
            INFER_SCHEMA(
                LOCATION    => '@RAW.TAXI_INT_STAGE',
                FILE_FORMAT => 'RAW.TAXI_PARQUET_FF',
                FILES       => 'yellow_tripdata_2025-01.parquet'
            )
        )
    );
```

### Colonnes détectées (20 colonnes Parquet + 2 techniques)

| Colonne | Type | Description |
|---------|------|-------------|
| VendorID | NUMBER | Identifiant du fournisseur (1=CMT, 2=VFI) |
| tpep_pickup_datetime | NUMBER → TIMESTAMP | Date/heure de prise en charge |
| tpep_dropoff_datetime | NUMBER → TIMESTAMP | Date/heure de dépose |
| passenger_count | NUMBER | Nombre de passagers |
| trip_distance | REAL | Distance du trajet (miles) |
| RatecodeID | NUMBER | Code tarif (1=Standard, 2=JFK, etc.) |
| store_and_fwd_flag | TEXT | Y/N — trajet stocké avant envoi |
| PULocationID | NUMBER | Zone de prise en charge (TLC zone ID) |
| DOLocationID | NUMBER | Zone de dépose (TLC zone ID) |
| payment_type | NUMBER | Mode de paiement (1=CB, 2=Cash, etc.) |
| fare_amount | REAL | Tarif de base |
| extra | REAL | Suppléments (heure de pointe, nuit) |
| mta_tax | REAL | Taxe MTA |
| tip_amount | REAL | Pourboire |
| tolls_amount | REAL | Péages |
| improvement_surcharge | REAL | Surtaxe d'amélioration |
| total_amount | REAL | Montant total |
| congestion_surcharge | REAL | Surtaxe de congestion |
| Airport_fee | REAL | Frais aéroport |
| cbd_congestion_fee | REAL | Frais congestion CBD |
| _source_file | VARCHAR | Nom du fichier Parquet source (traçabilité) |
| _loaded_at | TIMESTAMP_NTZ | Date/heure de chargement |

## Méthode de nettoyage (RAW → STAGING)

Le nettoyage historique est effectué dans `sql/02_staging.sql`.
La version de référence du projet est désormais implémentée dans
`models/staging/stg_yellow_taxi_trips.sql` puis
`models/intermediate/int_trip_metrics.sql`.

Sur 55.8M de lignes brutes, **50.5M sont conservées** après filtrage et
enrichissement.

### Conversion des types

Les colonnes `tpep_pickup_datetime` et `tpep_dropoff_datetime` sont stockées
comme `NUMBER(38,0)` dans le Parquet. Elles sont converties en TIMESTAMP via :

```sql
TO_TIMESTAMP_NTZ("tpep_pickup_datetime", 6)
```

### Filtres appliqués

| Filtre | Condition SQL | Raison |
|--------|--------------|--------|
| Montants négatifs | `fare_amount >= 0 AND total_amount >= 0` | Élimine les remboursements et erreurs de saisie |
| Dates incohérentes | `pickup_datetime < dropoff_datetime` | Élimine les trajets où la dépose précède la prise en charge |
| Valeurs manquantes | `PULocationID IS NOT NULL AND DOLocationID IS NOT NULL` | Élimine les trajets sans zone géographique |
| Outliers distance | `trip_distance BETWEEN 0.1 AND 100` | Élimine les distances nulles et > 100 miles |
| Outliers durée | `DATEDIFF(minute, pickup, dropoff) BETWEEN 1 AND 300` | Élimine les trajets < 1 min ou > 5h |

### Colonnes calculées ajoutées

| Colonne | Formule | Description |
|---------|---------|-------------|
| trip_duration_minutes | `DATEDIFF('minute', pickup, dropoff)` | Durée du trajet en minutes |
| pickup_hour | `HOUR(pickup)` | Heure de prise en charge (0-23) |
| pickup_day_of_week_num | `DAYOFWEEK(pickup)` | Jour de la semaine |
| pickup_month | `MONTH(pickup)` | Mois (1-12) |
| pickup_year | `YEAR(pickup)` | Année |
| pickup_date | `DATE(pickup)` | Date (sans heure) |
| avg_speed_mph | `distance / (durée / 60)` | Vitesse moyenne en miles/heure |
| taux_pourboire | `(tip_amount / fare_amount) * 100` | Pourcentage du pourboire par rapport au tarif de base |

## Tables analytiques (STAGING → FINAL)

### FINAL.fact_trips

Table de faits détaillée, une ligne par trajet, utilisée comme base analytique
pour les marts et les visualisations.

### FINAL.daily_summary (429 lignes)

Métriques agrégées **par jour** :

- nombre total de trajets
- distance moyenne
- durée moyenne
- revenus totaux et moyens par trajet
- pourboire moyen (%)
- nombre total de passagers

### FINAL.zone_analysis (262 lignes)

Métriques agrégées **par zone de départ** :

- volume de trajets
- revenu moyen et total
- distance moyenne
- pourboire moyen (%)
- nombre de jours actifs

### FINAL.hourly_patterns (168 lignes)

Métriques agrégées **par heure × jour de la semaine** :

- volume de trajets
- revenu moyen
- distance moyenne
- vitesse moyenne
- pourboire moyen (%)

## Modèles dbt (Partie 2)

La partie avancée est implémentée avec `dbt`, en complément des scripts SQL
historiques.

### Staging

- `models/staging/stg_yellow_taxi_trips.sql`
  - conversion des timestamps Parquet
  - renommage en `snake_case`
  - filtres de qualité sur les montants, distances, durées et zones

### Intermediate

- `models/intermediate/int_trip_metrics.sql`
  - calcul de `trip_duration_minutes`, `avg_speed_mph`, `taux_pourboire`
  - catégorisation des distances
  - catégorisation des périodes temporelles
  - typologie `jour_semaine` / `weekend`

### Marts

- `models/marts/fact_trips.sql` : table de faits principale
- `models/marts/daily_summary.sql` : agrégations journalières
- `models/marts/zone_analysis.sql` : analyse par zone de pickup
- `models/marts/hourly_patterns.sql` : patterns par heure et jour de semaine

### Tests et documentation

- tests génériques via les fichiers YAML `models/**.yml`
- tests SQL dans le dossier `tests/`
- documentation générable avec `uv run dbt docs generate --profiles-dir .`
- wrapper pratique via `./run_dbt.sh ...` ou `make dbt-run`

## Stack technique

- **Snowflake** — data warehouse
- **Python 3.12** — orchestration des scripts
- **snowflake-connector-python** — connexion Python ↔ Snowflake
- **dbt-core** — moteur dbt
- **dbt-snowflake** — adapter dbt pour Snowflake
- **uv** — gestionnaire de paquets Python
- **Ruff / Pyright / pytest / Bandit / pre-commit** — qualité et validation
- **MkDocs** — documentation technique du dépôt
- **Evidence** — visualisation et dashboards analytiques
- **VSCode** + extension Snowflake — exécution des requêtes SQL

## Conventions de projet

Les conventions d'outillage et de qualité du dépôt sont formalisées dans
[CONTRIBUTING.md](/home/maxime/simplonalternance/snowflake/CONTRIBUTING.md).

## Utilisation

### Prérequis

- compte Snowflake actif
- Python `>=3.12,<3.13` et `uv` installés
- fichiers Parquet locaux dans `/home/maxime/Téléchargements/Taxi/` si
  `TAXI_SOURCE_MODE=local`

### Exécution

```bash
# 1. Configurer les credentials
cp .env.example .env
# Éditer .env avec tes identifiants Snowflake

# 2. Installer les dépendances du projet
uv sync --all-groups

# 3. Charger les données (PUT → stage → COPY INTO)
uv run python load_data.py

# 4. Transformer avec les scripts SQL historiques
uv run python transform.py

# 5. Transformer avec dbt
./run_dbt.sh debug
./run_dbt.sh run
./run_dbt.sh test

# 6. Générer / servir la documentation dbt
./run_dbt.sh docs generate
./run_dbt.sh docs serve

# 7. Vérifier l'installation dbt
uv run dbt --version

# 8. Lancer la chaîne qualité locale
uv run pre-commit run --all-files
uv run pytest
uv run pyright

# 9. Construire la documentation technique
uv run mkdocs build
```

`dbt-core` fournit le moteur dbt, mais ne sait pas parler à un entrepôt tout
seul. `dbt-snowflake` est l'adapter qui permet à dbt de se connecter à
Snowflake, compiler le SQL au bon dialecte et exécuter les modèles.

### Ingestion locale ou distante

`load_data.py` supporte deux modes :

- `TAXI_SOURCE_MODE=local` : charge les fichiers présents dans `TAXI_LOCAL_DIR`
- `TAXI_SOURCE_MODE=remote` : résout d'abord le lien mensuel depuis la page
  officielle TLC `TLC_DATA_PAGE`, puis télécharge le fichier

Tu peux cibler un ou plusieurs mois précis avec `TAXI_MONTHS` :

```bash
# Un seul mois
TAXI_SOURCE_MODE=remote TAXI_MONTHS=2026-02 uv run python load_data.py

# Plusieurs mois
TAXI_MONTHS=2026-01,2026-02 uv run python load_data.py
```

Sans `TAXI_MONTHS` en mode `remote`, le script prend automatiquement le dernier
mois Yellow Taxi effectivement publié sur la page officielle TLC.

### Profil dbt

Le fichier `profiles.yml` est versionné dans le dépôt et lit les credentials
Snowflake via des variables d'environnement shell.

Important :

- les scripts Python (`load_data.py`, `setup.py`, `transform.py`) chargent
  `.env` automatiquement avec `python-dotenv`
- `dbt` ne lit pas `.env` tout seul
- `./run_dbt.sh` charge `.env` automatiquement avant d'exécuter `dbt`
- les cibles `make dbt-debug`, `make dbt-run`, `make dbt-test`,
  `make dbt-docs-generate` et `make dbt-docs-serve` utilisent ce wrapper

### Vérification

Ouvrir `sql/04_verification.sql` dans VSCode et exécuter bloc par bloc.

### GitHub Actions

Le dépôt contient deux workflows :

- `.github/workflows/monthly_pipeline.yml`
- `.github/workflows/ci.yml`

Le workflow `monthly_pipeline.yml` permet :

- un déclenchement mensuel automatique le 1er de chaque mois
- un lancement manuel avec choix du mois à charger
- une ingestion distante TLC
- sans `data_month`, le workflow prend automatiquement le dernier mois Yellow
  Taxi effectivement publié sur la page officielle TLC
- l'exécution de `dbt run` puis `dbt test`

Le workflow `ci.yml` exécute :

- `pre-commit`
- `ruff check`
- `ruff format --check`
- `pyright`
- `bandit`
- `pip-audit` non bloquant
- `pytest`

Secrets GitHub à configurer :

- `SNOWFLAKE_ACCOUNT`
- `SNOWFLAKE_USER`
- `SNOWFLAKE_PASSWORD`
- `SNOWFLAKE_WAREHOUSE`
- `SNOWFLAKE_DATABASE`
- `SNOWFLAKE_ROLE`

### Evidence

Le sous-projet `evidence/` fournit les pages de visualisation adossées aux
tables `FINAL.*`.

Commandes utiles :

```bash
# Extraire les datasets Evidence depuis Snowflake
./run_evidence.sh sources

# Lancer le serveur local Evidence
./run_evidence.sh dev

# Générer le build statique
./run_evidence.sh build
```

Ou via `make` :

```bash
make evidence-sources
make evidence-dev
make evidence-build
```

## Structure du projet

```text
snowflake/
├── CONTRIBUTING.md
├── .github/workflows/ci.yml
├── .github/workflows/monthly_pipeline.yml
├── .env.example
├── .pre-commit-config.yaml
├── Makefile
├── dbt_project.yml
├── docs/
├── evidence/
├── load_data.py
├── macros/
│   └── generate_schema_name.sql
├── mkdocs.yml
├── models/
│   ├── sources.yml
│   ├── staging/
│   │   ├── stg_yellow_taxi_trips.sql
│   │   └── staging.yml
│   ├── intermediate/
│   │   ├── int_trip_metrics.sql
│   │   └── intermediate.yml
│   └── marts/
│       ├── fact_trips.sql
│       ├── daily_summary.sql
│       ├── zone_analysis.sql
│       ├── hourly_patterns.sql
│       └── marts.yml
├── profiles.yml
├── pyproject.toml
├── pyrightconfig.json
├── run_dbt.sh
├── run_evidence.sh
├── setup.py
├── sql/
│   ├── 00_*.sql
│   ├── 01_setup.sql
│   ├── 02_staging.sql
│   ├── 03_final.sql
│   └── 04_verification.sql
├── tests/
│   ├── assert_stg_trip_bounds.sql
│   ├── assert_int_metric_ranges.sql
│   ├── assert_hourly_patterns_grain.sql
│   └── test_load_data.py
├── transform.py
└── uv.lock
```
