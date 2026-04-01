-- Diagnostic : compare les colonnes de la table vs le Parquet
USE DATABASE NYC_TAXI_DB;
USE WAREHOUSE NYC_TAXI_WH;

-- 1. Colonnes actuelles de la table
DESCRIBE TABLE RAW.yellow_taxi_trips;

-- 2. Colonnes détectées dans le Parquet
SELECT *
FROM TABLE(
    INFER_SCHEMA(
        LOCATION    => '@NYC_TAXI_DB.RAW.TAXI_INT_STAGE',
        FILE_FORMAT => 'NYC_TAXI_DB.RAW.TAXI_PARQUET_FF',
        FILES       => 'yellow_tripdata_2025-01.parquet'
    )
);


SELECT COUNT(*) FROM NYC_TAXI_DB.RAW.yellow_taxi_trips;

SELECT COUNT(*) FROM NYC_TAXI_DB.FINAL.daily_summary;
