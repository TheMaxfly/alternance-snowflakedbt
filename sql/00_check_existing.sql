-- ============================================================
-- 00_check_existing.sql : Inventaire de l'existant
-- Exécute bloc par bloc (Ctrl+Enter sur chaque bloc)
-- ============================================================

USE DATABASE NYC_TAXI_DB;

-- 1. Tables dans chaque schéma
SHOW TABLES IN SCHEMA RAW;
SHOW TABLES IN SCHEMA STAGING;
SHOW TABLES IN SCHEMA FINAL;

-- 2. Stages existants
SHOW STAGES IN SCHEMA RAW;

-- 3. File formats existants
SHOW FILE FORMATS IN SCHEMA RAW;

-- 4. Storage integrations
SHOW INTEGRATIONS;
