-- ============================================================
-- 04_verification.sql : Visualisation des résultats
-- ============================================================

USE DATABASE NYC_TAXI_DB;

-- ── Volume par couche ─────────────────────────────────────────
SELECT 'RAW.yellow_taxi_trips' AS table_name, COUNT(*) AS nb_lignes FROM RAW.yellow_taxi_trips       UNION ALL
SELECT 'STAGING.stg_yellow_taxi_trips',        COUNT(*)              FROM STAGING.stg_yellow_taxi_trips UNION ALL
SELECT 'STAGING.int_trip_metrics',             COUNT(*)              FROM STAGING.int_trip_metrics     UNION ALL
SELECT 'FINAL.fact_trips',                     COUNT(*)              FROM FINAL.fact_trips             UNION ALL
SELECT 'FINAL.daily_summary',                  COUNT(*)              FROM FINAL.daily_summary          UNION ALL
SELECT 'FINAL.zone_analysis',                  COUNT(*)              FROM FINAL.zone_analysis          UNION ALL
SELECT 'FINAL.hourly_patterns',                COUNT(*)              FROM FINAL.hourly_patterns;

-- ── Aperçu STAGING : 10 premières lignes nettoyées ───────────
SELECT * FROM STAGING.stg_yellow_taxi_trips LIMIT 10;

-- ── Aperçu FACT : 10 premières lignes enrichies ──────────────
SELECT * FROM FINAL.fact_trips LIMIT 10;

-- ── FINAL : Résumé quotidien (derniers jours) ────────────────
SELECT * FROM FINAL.daily_summary ORDER BY pickup_date DESC LIMIT 20;

-- ── FINAL : Top 10 zones les plus fréquentées ────────────────
SELECT * FROM FINAL.zone_analysis ORDER BY total_trips DESC LIMIT 10;

-- ── FINAL : Patterns horaires (heure de pointe) ──────────────
SELECT
    pickup_hour,
    SUM(total_trips) AS total_trips,
    ROUND(AVG(avg_revenue), 2) AS avg_revenue,
    ROUND(AVG(avg_speed_mph), 2) AS avg_speed
FROM FINAL.hourly_patterns
GROUP BY pickup_hour
ORDER BY pickup_hour;
