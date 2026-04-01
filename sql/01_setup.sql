-- ============================================================
-- 01_setup.sql : Infrastructure Snowflake NYC Taxi Pipeline
-- Exécuter bloc par bloc dans VSCode (Ctrl+Enter)
-- ============================================================

USE DATABASE NYC_TAXI_DB;
USE WAREHOUSE NYC_TAXI_WH;

-- ── 1. Schémas ────────────────────────────────────────────────
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS STAGING;
CREATE SCHEMA IF NOT EXISTS FINAL;

-- ── 2. File format Parquet ────────────────────────────────────
CREATE OR REPLACE FILE FORMAT NYC_TAXI_DB.RAW.TAXI_PARQUET_FF
    TYPE = 'PARQUET'
    SNAPPY_COMPRESSION = TRUE;

-- ── 3. Stage interne ─────────────────────────────────────────
-- Pas d'URL externe nécessaire : les fichiers locaux sont
-- uploadés via PUT (script Python load_data.py)
CREATE OR REPLACE STAGE NYC_TAXI_DB.RAW.TAXI_INT_STAGE
    FILE_FORMAT = NYC_TAXI_DB.RAW.TAXI_PARQUET_FF;

-- Vérifie que le stage existe
SHOW STAGES IN SCHEMA NYC_TAXI_DB.RAW;

-- ── 4. Création automatique de la table RAW ───────────────────
-- PRÉREQUIS : lancer d'abord "uv run python load_data.py"
-- pour que les fichiers soient dans le stage.
-- Ensuite exécuter ce bloc :

CREATE OR REPLACE TABLE NYC_TAXI_DB.RAW.yellow_taxi_trips
    USING TEMPLATE (
        SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
        FROM TABLE(
            INFER_SCHEMA(
                LOCATION    => '@NYC_TAXI_DB.RAW.TAXI_INT_STAGE',
                FILE_FORMAT => 'NYC_TAXI_DB.RAW.TAXI_PARQUET_FF',
                FILES       => 'yellow_tripdata_2026-01.parquet'
            )
        )
    );

-- ── 5. Colonnes techniques ────────────────────────────────────
ALTER TABLE NYC_TAXI_DB.RAW.yellow_taxi_trips
    ADD COLUMN IF NOT EXISTS _source_file VARCHAR;

ALTER TABLE NYC_TAXI_DB.RAW.yellow_taxi_trips
    ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP();

-- Vérifie les colonnes détectées automatiquement
DESCRIBE TABLE NYC_TAXI_DB.RAW.yellow_taxi_trips;
