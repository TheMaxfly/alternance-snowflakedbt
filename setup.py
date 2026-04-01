"""
setup.py
1. Crée warehouse, schémas, file format, intégration GCS, stage
2. Télécharge le fichier Parquet de référence (2026-01) et l'uploade dans GCS
   → nécessaire pour que INFER_SCHEMA fonctionne dans 01_setup.sql
3. Affiche le rappel : créer la table via 01_setup.sql dans VSCode
"""

import os
import tempfile

import requests
import snowflake.connector
from dotenv import load_dotenv
from google.cloud import storage as gcs

load_dotenv()

BASE_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data"
GCS_BUCKET = os.environ["GCS_BUCKET_NAME"]
GCS_PREFIX = os.environ.get("GCS_PREFIX", "yellow_taxi/")
GCS_KEY = os.environ.get("GCS_KEY_FILE")

# Fichier de référence pour INFER_SCHEMA
FICHIER_REF = "yellow_tripdata_2026-01.parquet"


def get_snowflake():
    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        role=os.environ.get("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
    )


def get_gcs_client():
    if GCS_KEY:
        return gcs.Client.from_service_account_json(GCS_KEY)
    return gcs.Client()


def executer(cur, sql: str, label: str = ""):
    if label:
        print(f"  → {label}")
    cur.execute(sql)
    print("  ✓ OK")


def main():
    print("=" * 60)
    print("  Setup infrastructure Snowflake NYC Taxi")
    print("=" * 60)

    con = get_snowflake()
    cur = con.cursor()

    try:
        # ── Étape 1 : infrastructure de base ──────────────────
        print("\n[1/4] Warehouse & Database")
        executer(
            cur,
            """
            CREATE WAREHOUSE IF NOT EXISTS NYC_TAXI_WH
                WAREHOUSE_SIZE = 'MEDIUM'
                AUTO_SUSPEND = 60
                AUTO_RESUME = TRUE
        """,
            "Warehouse NYC_TAXI_WH",
        )

        executer(
            cur, "CREATE DATABASE IF NOT EXISTS NYC_TAXI_DB", "Database NYC_TAXI_DB"
        )
        executer(cur, "USE DATABASE NYC_TAXI_DB", "USE NYC_TAXI_DB")

        print("\n[2/4] Schémas & File format")
        for schema in ["RAW", "STAGING", "FINAL"]:
            executer(cur, f"CREATE SCHEMA IF NOT EXISTS {schema}", f"Schema {schema}")

        executer(
            cur,
            """
            CREATE OR REPLACE FILE FORMAT NYC_TAXI_DB.RAW.TAXI_PARQUET_FF
                TYPE = 'PARQUET'
                SNAPPY_COMPRESSION = TRUE
        """,
            "File format TAXI_PARQUET_FF",
        )

        # ── Étape 2 : intégration GCS ─────────────────────────
        print("\n[3/4] Intégration GCS & Stage")
        executer(
            cur,
            """
            CREATE STORAGE INTEGRATION IF NOT EXISTS GCS_NYC_TAXI_INT
                TYPE = EXTERNAL_STAGE
                STORAGE_PROVIDER = 'GCS'
                ENABLED = TRUE
                STORAGE_ALLOWED_LOCATIONS = ('gcs://nyc-taxi-data-pipeline/yellow_taxi/')
        """,
            "Storage Integration GCS_NYC_TAXI_INT",
        )

        # Affiche le service account à autoriser dans GCS
        cur.execute("DESC INTEGRATION GCS_NYC_TAXI_INT")
        rows = cur.fetchall()
        for row in rows:
            if "SERVICE_ACCOUNT" in str(row[0]).upper():
                print("\n  !! Service account GCS à autoriser dans IAM :")
                print(f"     {row[2]}")
                print("     → Rôle requis : Storage Object Admin\n")

        executer(
            cur,
            """
            CREATE OR REPLACE STAGE NYC_TAXI_DB.RAW.TAXI_GCS_STAGE
                URL = 'gcs://nyc-taxi-data-pipeline/yellow_taxi/'
                STORAGE_INTEGRATION = GCS_NYC_TAXI_INT
                FILE_FORMAT = NYC_TAXI_DB.RAW.TAXI_PARQUET_FF
        """,
            "Stage TAXI_GCS_STAGE",
        )

        # ── Étape 3 : upload fichier de référence dans GCS ────
        print(f"\n[4/4] Upload du fichier de référence dans GCS ({FICHIER_REF})")
        client_gcs = get_gcs_client()
        bucket = client_gcs.bucket(GCS_BUCKET)
        blob = bucket.blob(f"{GCS_PREFIX}{FICHIER_REF}")

        if blob.exists():
            print("  ✓ Déjà présent dans GCS — rien à faire")
        else:
            url = f"{BASE_URL}/{FICHIER_REF}"
            print(f"  → Téléchargement : {url}")
            r = requests.get(url, stream=True, timeout=120)
            r.raise_for_status()

            with tempfile.TemporaryDirectory() as tmp:
                chemin = os.path.join(tmp, FICHIER_REF)
                with open(chemin, "wb") as f:
                    for chunk in r.iter_content(chunk_size=8 * 1024 * 1024):
                        f.write(chunk)
                mo = os.path.getsize(chemin) / (1024 * 1024)
                print(f"  ✓ Téléchargé ({mo:.1f} MB)")

                print("  → Upload vers GCS...")
                blob.upload_from_filename(chemin, timeout=300)
                print(f"  ✓ Disponible : gs://{GCS_BUCKET}/{GCS_PREFIX}{FICHIER_REF}")

    finally:
        cur.close()
        con.close()

    print("\n" + "=" * 60)
    print("  Setup terminé.")
    print("\n  Prochaine étape dans VSCode :")
    print("  Ouvre sql/01_setup.sql et exécute le bloc 6")
    print("  (CREATE TABLE USING TEMPLATE avec INFER_SCHEMA)")
    print("=" * 60)


if __name__ == "__main__":
    main()
