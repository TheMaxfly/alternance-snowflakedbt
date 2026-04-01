"""
load_data.py
1. Crée le stage interne + file format (si inexistants)
2. Prépare les fichiers Parquet depuis un dossier local ou depuis TLC
3. PUT : uploade les fichiers préparés dans un dossier temp (sans accents)
4. INFER_SCHEMA : crée la table RAW avec les colonnes du Parquet (si inexistante)
5. COPY INTO : charge les données dans RAW.yellow_taxi_trips
"""

import os
import glob
import re
import shutil
import tempfile
from urllib.parse import urljoin
import snowflake.connector
import requests
from dotenv import load_dotenv

load_dotenv()

BASE_URL = os.environ.get("TAXI_BASE_URL", "https://d37ci6vzurychx.cloudfront.net/trip-data")
TLC_DATA_PAGE = os.environ.get(
    "TLC_DATA_PAGE",
    "https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page",
)
DOSSIER_LOCAL = os.environ.get("TAXI_LOCAL_DIR", "/home/maxime/Téléchargements/Taxi")
SOURCE_MODE = os.environ.get("TAXI_SOURCE_MODE", "local").lower()
RAW_MONTHS = os.environ.get("TAXI_MONTHS", "").strip()

STAGE = "@NYC_TAXI_DB.RAW.TAXI_INT_STAGE"
TABLE = "NYC_TAXI_DB.RAW.yellow_taxi_trips"
FILE_FORMAT = "NYC_TAXI_DB.RAW.TAXI_PARQUET_FF"
MONTH_PATTERN = re.compile(r"^\d{4}-\d{2}$")


def get_connection():
    return snowflake.connector.connect(
        account   = os.environ["SNOWFLAKE_ACCOUNT"],
        user      = os.environ["SNOWFLAKE_USER"],
        password  = os.environ["SNOWFLAKE_PASSWORD"],
        warehouse = os.environ["SNOWFLAKE_WAREHOUSE"],
        database  = os.environ["SNOWFLAKE_DATABASE"],
        role      = os.environ.get("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
    )


def parse_target_months() -> list[str]:
    if not RAW_MONTHS:
        return []

    mois = [m.strip() for m in RAW_MONTHS.split(",") if m.strip()]
    invalides = [m for m in mois if not MONTH_PATTERN.match(m)]
    if invalides:
        raise ValueError(
            "TAXI_MONTHS doit contenir des mois au format YYYY-MM. "
            f"Valeurs invalides : {', '.join(invalides)}"
        )
    return sorted(set(mois))


def build_expected_filenames(mois: list[str]) -> list[str]:
    return [f"yellow_tripdata_{mois_cible}.parquet" for mois_cible in mois]


def resolve_tlc_download_url(nom_fichier: str) -> str:
    """Resolve the monthly Yellow Taxi download URL from the official TLC page.

    The official page currently links to CloudFront assets. We resolve the URL
    from that page first to avoid hard-coding the CDN path as the only source
    of truth. If the page format changes or is unavailable, we fall back to the
    historical direct URL pattern.
    """
    fallback_url = f"{BASE_URL}/{nom_fichier}"
    try:
        reponse = requests.get(TLC_DATA_PAGE, timeout=60)
        reponse.raise_for_status()
    except requests.RequestException as erreur:
        print(f"  ! Page TLC indisponible, fallback direct utilise: {erreur}")
        return fallback_url

    motif = re.compile(
        rf'href="(?P<url>[^"]*{re.escape(nom_fichier)}(?:\?[^"]*)?)"',
        re.IGNORECASE,
    )
    correspondance = motif.search(reponse.text)
    if correspondance:
        return urljoin(TLC_DATA_PAGE, correspondance.group("url"))

    print(f"  ! Lien {nom_fichier} introuvable sur la page TLC, fallback direct utilise")
    return fallback_url


def prepare_local_files(tmp_dir: str, fichiers_attendus: list[str]) -> list[str]:
    if fichiers_attendus:
        fichiers_source = [os.path.join(DOSSIER_LOCAL, nom) for nom in fichiers_attendus]
    else:
        fichiers_source = sorted(glob.glob(os.path.join(DOSSIER_LOCAL, "yellow_tripdata_*.parquet")))

    manquants = [f for f in fichiers_source if not os.path.exists(f)]
    if manquants:
        raise FileNotFoundError(f"Fichiers introuvables dans {DOSSIER_LOCAL} : {', '.join(manquants)}")

    chemins_prepares = []
    for chemin in fichiers_source:
        nom = os.path.basename(chemin)
        chemin_tmp = os.path.join(tmp_dir, nom)
        shutil.copy2(chemin, chemin_tmp)
        chemins_prepares.append(chemin_tmp)
    return chemins_prepares


def prepare_remote_files(tmp_dir: str, fichiers_attendus: list[str]) -> list[str]:
    if not fichiers_attendus:
        raise ValueError("En mode remote, TAXI_MONTHS est requis pour cibler les mois à charger.")

    chemins_prepares = []
    for nom in fichiers_attendus:
        url = resolve_tlc_download_url(nom)
        chemin_tmp = os.path.join(tmp_dir, nom)
        print(f"  ↓ Téléchargement {nom}")
        print(f"    Source: {url}")
        reponse = requests.get(url, stream=True, timeout=300)
        reponse.raise_for_status()
        with open(chemin_tmp, "wb") as fichier:
            for chunk in reponse.iter_content(chunk_size=8 * 1024 * 1024):
                if chunk:
                    fichier.write(chunk)
        chemins_prepares.append(chemin_tmp)
    return chemins_prepares


def prepare_source_files(tmp_dir: str) -> list[str]:
    mois = parse_target_months()
    fichiers_attendus = build_expected_filenames(mois)

    if SOURCE_MODE == "local":
        return prepare_local_files(tmp_dir, fichiers_attendus)
    if SOURCE_MODE == "remote":
        return prepare_remote_files(tmp_dir, fichiers_attendus)

    raise ValueError("TAXI_SOURCE_MODE doit valoir 'local' ou 'remote'.")


# ── Étape 0 : créer le stage et file format ──────────────────────────────────
def creer_infrastructure(cur):
    """Crée le file format et le stage interne s'ils n'existent pas."""
    print("\n[0/3] Infrastructure (file format + stage interne)")

    cur.execute("""
        CREATE FILE FORMAT IF NOT EXISTS NYC_TAXI_DB.RAW.TAXI_PARQUET_FF
            TYPE = 'PARQUET'
            SNAPPY_COMPRESSION = TRUE
    """)
    print("  ✓ File format TAXI_PARQUET_FF")

    cur.execute("""
        CREATE STAGE IF NOT EXISTS NYC_TAXI_DB.RAW.TAXI_INT_STAGE
            FILE_FORMAT = NYC_TAXI_DB.RAW.TAXI_PARQUET_FF
    """)
    print("  ✓ Stage interne TAXI_INT_STAGE")


# ── Étape 1 : PUT fichiers locaux → stage interne ─────────────────────────────
def put_fichiers(cur) -> list[str]:
    """Uploade les fichiers Parquet préparés dans le stage interne Snowflake."""
    print(f"\n[1/3] PUT — fichiers source → stage interne")
    print(f"  Mode source : {SOURCE_MODE}")

    with tempfile.TemporaryDirectory(prefix="nyc_taxi_") as tmp_dir:
        print(f"  Dossier temporaire : {tmp_dir}")
        fichiers = prepare_source_files(tmp_dir)

        if not fichiers:
            raise FileNotFoundError("Aucun fichier Parquet à charger.")

        print(f"  Fichiers préparés : {len(fichiers)}")
        noms_charges = []
        for chemin_tmp in fichiers:
            nom = os.path.basename(chemin_tmp)
            print(f"  → {nom} ...", end=" ", flush=True)
            cur.execute(f"PUT file://{chemin_tmp} {STAGE} AUTO_COMPRESS=FALSE OVERWRITE=FALSE")
            resultat = cur.fetchone()

            statut = resultat[6] if resultat else "?"
            print(statut)
            noms_charges.append(nom)

    return noms_charges


# ── Étape 2 : créer la table depuis le schéma Parquet ────────────────────────
def creer_table_depuis_parquet(cur, fichier_reference: str):
    """
    Utilise INFER_SCHEMA pour détecter automatiquement les colonnes
    et CREATE TABLE USING TEMPLATE pour créer la table sans typer manuellement.
    """
    print(f"\n[2/3] INFER_SCHEMA → CREATE TABLE USING TEMPLATE")
    print(f"  → Fichier de référence : {fichier_reference}")

    # Vérifie si la table existe déjà
    cur.execute("""
        SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'RAW'
        AND TABLE_NAME = 'YELLOW_TAXI_TRIPS'
    """)
    if cur.fetchone()[0] > 0:
        print(f"  ✓ Table déjà existante — INFER_SCHEMA ignoré")
        # Ajoute les colonnes techniques si absentes
        cur.execute(f"ALTER TABLE {TABLE} ADD COLUMN IF NOT EXISTS _source_file VARCHAR")
        cur.execute(f"ALTER TABLE {TABLE} ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_NTZ")
        print(f"  ✓ Colonnes techniques vérifiées")
        return

    # Création automatique depuis le Parquet
    cur.execute(f"""
        CREATE OR REPLACE TABLE {TABLE}
        USING TEMPLATE (
            SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
            FROM TABLE(
                INFER_SCHEMA(
                    LOCATION    => '{STAGE}',
                    FILE_FORMAT => '{FILE_FORMAT}',
                    FILES       => '{fichier_reference}'
                )
            )
        )
    """)
    print(f"  ✓ Table créée avec les colonnes détectées automatiquement")

    # Colonnes techniques
    cur.execute(f"ALTER TABLE {TABLE} ADD COLUMN IF NOT EXISTS _source_file VARCHAR")
    cur.execute(f"ALTER TABLE {TABLE} ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_NTZ")
    print(f"  ✓ Colonnes techniques ajoutées (_source_file, _loaded_at)")

    # Affiche les colonnes détectées
    cur.execute(f"DESCRIBE TABLE {TABLE}")
    colonnes = cur.fetchall()
    print(f"\n  Colonnes détectées ({len(colonnes)}) :")
    for col in colonnes:
        print(f"    {col[0]:<35} {col[1]}")


# ── Étape 3 : COPY INTO depuis le stage ───────────────────────────────────────
def copy_into(cur, noms_fichiers: list[str]):
    """Charge chaque fichier du stage dans la table RAW."""
    print(f"\n[3/3] COPY INTO {TABLE}")

    for nom in noms_fichiers:
        # Anti-doublon : vérifie si ce fichier est déjà chargé
        cur.execute(f"""
            SELECT COUNT(*) FROM {TABLE}
            WHERE _source_file LIKE '%{nom}%'
        """)
        if cur.fetchone()[0] > 0:
            print(f"  ⚠ {nom} — déjà chargé, ignoré")
            continue

        print(f"  → {nom} ...", end=" ", flush=True)
        cur.execute(f"""
            COPY INTO {TABLE}
            FROM {STAGE}/{nom}
            FILE_FORMAT = (TYPE = 'PARQUET')
            MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
            ON_ERROR = 'CONTINUE'
        """)

        resultats = cur.fetchall()
        for r in resultats:
            status      = r[1] if len(r) > 1 else "?"
            rows_parsed = r[2] if len(r) > 2 else 0
            rows_loaded = r[3] if len(r) > 3 else 0
            errors_seen = r[5] if len(r) > 5 else 0
            first_error = r[6] if len(r) > 6 else ""
            print(f"\n    Status: {status} | Parsed: {rows_parsed:,} | Loaded: {rows_loaded:,} | Errors: {errors_seen}")
            if first_error:
                print(f"    First error: {first_error}")

        # Remplit _source_file pour les lignes qui viennent d'être chargées
        cur.execute(f"""
            UPDATE {TABLE}
            SET _source_file = '{nom}', _loaded_at = CURRENT_TIMESTAMP()
            WHERE _source_file IS NULL
        """)


# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    print("=" * 60)
    print("  Pipeline NYC Yellow Taxi → Snowflake (stage interne)")
    print("=" * 60)

    con = get_connection()
    cur = con.cursor()

    try:
        creer_infrastructure(cur)
        noms_fichiers = put_fichiers(cur)
        creer_table_depuis_parquet(cur, noms_fichiers[0])
        copy_into(cur, noms_fichiers)
    finally:
        cur.close()
        con.close()

    print("\n" + "=" * 60)
    print("  Ingestion terminée.")
    print("  Lance maintenant : uv run dbt run --profiles-dir .")
    print("  Puis : uv run dbt test --profiles-dir .")
    print("=" * 60)


if __name__ == "__main__":
    main()
