-- ============================================================
-- 04_verification.sql : Visualisation des résultats
-- ============================================================

USE DATABASE NYC_TAXI_DB;
USE WAREHOUSE NYC_TAXI_WH;

-- ── Volume par couche ─────────────────────────────────────────
SELECT 'RAW.yellow_taxi_trips' AS table_name, COUNT(*) AS nb_lignes FROM NYC_TAXI_DB.RAW.yellow_taxi_trips              UNION ALL
SELECT 'STAGING.stg_yellow_taxi_trips',        COUNT(*)              FROM NYC_TAXI_DB.STAGING.stg_yellow_taxi_trips     UNION ALL
SELECT 'STAGING.int_trip_metrics',             COUNT(*)              FROM NYC_TAXI_DB.STAGING.int_trip_metrics          UNION ALL
SELECT 'FINAL.fact_trips',                     COUNT(*)              FROM NYC_TAXI_DB.FINAL.fact_trips                  UNION ALL
SELECT 'FINAL.daily_summary',                  COUNT(*)              FROM NYC_TAXI_DB.FINAL.daily_summary               UNION ALL
SELECT 'FINAL.zone_analysis',                  COUNT(*)              FROM NYC_TAXI_DB.FINAL.zone_analysis               UNION ALL
SELECT 'FINAL.hourly_patterns',                COUNT(*)              FROM NYC_TAXI_DB.FINAL.hourly_patterns;

-- ── Aperçu STAGING : 10 premières lignes nettoyées ───────────
SELECT
    pickup_datetime,
    dropoff_datetime,
    trip_distance,
    fare_amount,
    total_amount,
    pickup_hour,
    pickup_day_name
FROM NYC_TAXI_DB.STAGING.stg_yellow_taxi_trips
LIMIT 10;

-- ── Aperçu FACT : 10 premières lignes enrichies ──────────────
SELECT
    pickup_datetime,
    dropoff_datetime,
    trip_distance,
    trip_duration_minutes,
    avg_speed_mph,
    taux_pourboire,
    distance_category,
    time_period,
    day_type
FROM NYC_TAXI_DB.FINAL.fact_trips
LIMIT 10;

-- ── FINAL : Résumé quotidien (derniers jours) ────────────────
SELECT * FROM NYC_TAXI_DB.FINAL.daily_summary ORDER BY pickup_date DESC LIMIT 20;

-- ── FINAL : Top 10 zones les plus fréquentées ────────────────
SELECT * FROM NYC_TAXI_DB.FINAL.zone_analysis ORDER BY total_trips DESC LIMIT 10;

-- ── FINAL : Patterns horaires (heure de pointe) ──────────────
SELECT
    pickup_hour,
    SUM(total_trips) AS total_trips,
    ROUND(AVG(avg_revenue), 2) AS avg_revenue,
    ROUND(AVG(avg_speed_mph), 2) AS avg_speed
FROM NYC_TAXI_DB.FINAL.hourly_patterns
GROUP BY pickup_hour
ORDER BY pickup_hour;

-- ── Répartition des catégories de distance ───────────────────
SELECT
    distance_category,
    COUNT(*) AS total_trips,
    ROUND(AVG(trip_distance), 2) AS avg_distance,
    ROUND(AVG(taux_pourboire), 2) AS avg_taux_pourboire_pct
FROM NYC_TAXI_DB.FINAL.fact_trips
GROUP BY distance_category
ORDER BY total_trips DESC;

-- ── Répartition des périodes temporelles ─────────────────────
SELECT
    time_period,
    COUNT(*) AS total_trips,
    ROUND(AVG(avg_speed_mph), 2) AS avg_speed_mph,
    ROUND(AVG(taux_pourboire), 2) AS avg_taux_pourboire_pct
FROM NYC_TAXI_DB.FINAL.fact_trips
GROUP BY time_period
ORDER BY total_trips DESC;

-- ── Répartition semaine / weekend ────────────────────────────
SELECT
    day_type,
    COUNT(*) AS total_trips,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration_min,
    ROUND(AVG(taux_pourboire), 2) AS avg_taux_pourboire_pct
FROM NYC_TAXI_DB.FINAL.fact_trips
GROUP BY day_type
ORDER BY total_trips DESC;
