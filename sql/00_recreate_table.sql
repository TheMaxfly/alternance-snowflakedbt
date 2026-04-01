-- Recrée la table RAW avec les colonnes détectées depuis le Parquet
USE DATABASE NYC_TAXI_DB;
USE WAREHOUSE NYC_TAXI_WH;

-- Supprime l'ancienne table (1 seule colonne VARIANT_COL, inutilisable)
DROP TABLE IF EXISTS RAW.yellow_taxi_trips;

-- Recrée avec INFER_SCHEMA : colonnes automatiques depuis le Parquet
CREATE TABLE RAW.yellow_taxi_trips
    USING TEMPLATE (
        SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
        FROM TABLE(
            INFER_SCHEMA(
                LOCATION    => '@NYC_TAXI_DB.RAW.TAXI_INT_STAGE',
                FILE_FORMAT => 'NYC_TAXI_DB.RAW.TAXI_PARQUET_FF',
                FILES       => 'yellow_tripdata_2025-01.parquet'
            )
        )
    );

-- Ajoute les colonnes techniques
ALTER TABLE RAW.yellow_taxi_trips ADD COLUMN _source_file VARCHAR;
ALTER TABLE RAW.yellow_taxi_trips ADD COLUMN _loaded_at TIMESTAMP_NTZ;

-- Vérifie : tu dois voir ~22 colonnes (20 du Parquet + 2 techniques)
DESCRIBE TABLE RAW.yellow_taxi_trips;
