-- ============================================================
-- 03_final.sql : Tables analytiques finales
-- ============================================================

USE DATABASE NYC_TAXI_DB;

-- ── 1. Résumé quotidien ───────────────────────────────────────
CREATE OR REPLACE TABLE FINAL.daily_summary AS
SELECT
    pickup_date,
    COUNT(*)                        AS total_trips,
    ROUND(AVG("trip_distance"), 2)  AS avg_distance_miles,
    ROUND(AVG(trip_duration_minutes), 1) AS avg_duration_min,
    ROUND(SUM("total_amount"), 2)   AS total_revenue,
    ROUND(AVG("total_amount"), 2)   AS avg_revenue_per_trip,
    ROUND(AVG(taux_pourboire), 2)   AS avg_taux_pourboire_pct,
    SUM("passenger_count")          AS total_passengers
FROM STAGING.clean_trips
GROUP BY pickup_date
ORDER BY pickup_date;

-- ── 2. Analyse par zone de départ ────────────────────────────
CREATE OR REPLACE TABLE FINAL.zone_analysis AS
SELECT
    "PULocationID"                  AS pickup_zone_id,
    COUNT(*)                        AS total_trips,
    ROUND(AVG("total_amount"), 2)   AS avg_revenue,
    ROUND(SUM("total_amount"), 2)   AS total_revenue,
    ROUND(AVG("trip_distance"), 2)  AS avg_distance,
    ROUND(AVG(taux_pourboire), 2)   AS avg_taux_pourboire_pct,
    COUNT(DISTINCT pickup_date)     AS active_days
FROM STAGING.clean_trips
GROUP BY "PULocationID"
ORDER BY total_trips DESC;

-- ── 3. Patterns horaires ─────────────────────────────────────
CREATE OR REPLACE TABLE FINAL.hourly_patterns AS
SELECT
    pickup_hour,
    pickup_day_of_week,
    COUNT(*)                        AS total_trips,
    ROUND(AVG("total_amount"), 2)   AS avg_revenue,
    ROUND(AVG("trip_distance"), 2)  AS avg_distance,
    ROUND(AVG(avg_speed_mph), 2)    AS avg_speed_mph,
    ROUND(AVG(taux_pourboire), 2)   AS avg_taux_pourboire_pct
FROM STAGING.clean_trips
GROUP BY pickup_hour, pickup_day_of_week
ORDER BY pickup_day_of_week, pickup_hour;

-- ── Vérification ─────────────────────────────────────────────
SELECT 'daily_summary'    AS table_name, COUNT(*) AS nb_lignes FROM FINAL.daily_summary    UNION ALL
SELECT 'zone_analysis'    AS table_name, COUNT(*) AS nb_lignes FROM FINAL.zone_analysis    UNION ALL
SELECT 'hourly_patterns'  AS table_name, COUNT(*) AS nb_lignes FROM FINAL.hourly_patterns;
