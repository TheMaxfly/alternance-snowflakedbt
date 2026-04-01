-- ============================================================
-- 02_staging.sql : Nettoyage et enrichissement des données
-- Les colonnes datetime du Parquet sont en NUMBER (microsecondes)
-- → conversion via TO_TIMESTAMP_NTZ(..., 6)
-- ============================================================

USE DATABASE NYC_TAXI_DB;

CREATE OR REPLACE TABLE STAGING.clean_trips AS
WITH raw_converted AS (
    SELECT
        "VendorID",
        TO_TIMESTAMP_NTZ("tpep_pickup_datetime", 6)   AS tpep_pickup_datetime,
        TO_TIMESTAMP_NTZ("tpep_dropoff_datetime", 6)   AS tpep_dropoff_datetime,
        "passenger_count",
        "trip_distance",
        "RatecodeID",
        "store_and_fwd_flag",
        "PULocationID",
        "DOLocationID",
        "payment_type",
        "fare_amount",
        "extra",
        "mta_tax",
        "tip_amount",
        "tolls_amount",
        "improvement_surcharge",
        "total_amount",
        "congestion_surcharge",
        "Airport_fee",
        "cbd_congestion_fee",
        _SOURCE_FILE,
        _LOADED_AT
    FROM NYC_TAXI_DB.RAW.yellow_taxi_trips
)
SELECT
    "VendorID",
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    "passenger_count",
    "trip_distance",
    "RatecodeID",
    "store_and_fwd_flag",
    "PULocationID",
    "DOLocationID",
    "payment_type",
    "fare_amount",
    "extra",
    "mta_tax",
    "tip_amount",
    "tolls_amount",
    "improvement_surcharge",
    "total_amount",
    "congestion_surcharge",
    "Airport_fee",
    "cbd_congestion_fee",

    -- Enrichissements calculés
    DATEDIFF('minute', tpep_pickup_datetime, tpep_dropoff_datetime)     AS trip_duration_minutes,
    HOUR(tpep_pickup_datetime)                                           AS pickup_hour,
    DAYOFWEEK(tpep_pickup_datetime)                                      AS pickup_day_of_week,
    MONTH(tpep_pickup_datetime)                                          AS pickup_month,
    YEAR(tpep_pickup_datetime)                                           AS pickup_year,
    DATE(tpep_pickup_datetime)                                           AS pickup_date,

    CASE
        WHEN DATEDIFF('minute', tpep_pickup_datetime, tpep_dropoff_datetime) > 0
        THEN ROUND("trip_distance" / (DATEDIFF('minute', tpep_pickup_datetime, tpep_dropoff_datetime) / 60.0), 2)
        ELSE NULL
    END AS avg_speed_mph,

    CASE
        WHEN "fare_amount" > 0
        THEN ROUND(("tip_amount" / "fare_amount") * 100, 2)
        ELSE NULL
    END AS tip_percentage,

    _SOURCE_FILE,
    _LOADED_AT

FROM raw_converted

WHERE
    "fare_amount"     >= 0
    AND "total_amount" >= 0
    AND tpep_pickup_datetime < tpep_dropoff_datetime
    AND "trip_distance" BETWEEN 0.1 AND 100
    AND "PULocationID" IS NOT NULL
    AND "DOLocationID" IS NOT NULL
    AND DATEDIFF('minute', tpep_pickup_datetime, tpep_dropoff_datetime) BETWEEN 1 AND 300
;

SELECT COUNT(*) AS nb_lignes_staging FROM STAGING.clean_trips;
