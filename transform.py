"""
transform.py
Exécute les transformations SQL : RAW → STAGING → FINAL
"""

import os
import snowflake.connector
from dotenv import load_dotenv

load_dotenv()

SQL_DIR = os.path.join(os.path.dirname(__file__), "sql")


def get_connection():
    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
        database=os.environ["SNOWFLAKE_DATABASE"],
        role=os.environ.get("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
    )


def executer_sql_fichier(cur, chemin_fichier: str):
    """Exécute chaque instruction SQL d'un fichier (séparées par ;)."""
    with open(chemin_fichier, "r") as f:
        contenu = f.read()

    instructions = [s.strip() for s in contenu.split(";") if s.strip() and not s.strip().startswith("--")]

    for instruction in instructions:
        if not instruction:
            continue
        try:
            cur.execute(instruction)
            resultats = cur.fetchall()
            # Affiche les résultats des SELECT de vérification
            if resultats and instruction.strip().upper().startswith("SELECT"):
                for ligne in resultats:
                    print("   ", ligne)
        except Exception as e:
            print(f"  ✗ Erreur SQL : {e}")
            print(f"    Instruction : {instruction[:100]}...")
            raise


def main():
    print("=" * 60)
    print("  Transformations NYC Taxi : STAGING + FINAL")
    print("=" * 60)

    con = get_connection()
    cur = con.cursor()

    try:
        etapes = [
            ("STAGING — Nettoyage des données", "02_staging.sql"),
            ("FINAL — Tables analytiques", "03_final.sql"),
        ]

        for nom_etape, fichier_sql in etapes:
            print(f"\n[{nom_etape}]")
            chemin = os.path.join(SQL_DIR, fichier_sql)
            executer_sql_fichier(cur, chemin)
            print(f"  ✓ Terminé")

    finally:
        cur.close()
        con.close()

    print("\n" + "=" * 60)
    print("  Transformations terminées.")
    print("=" * 60)


if __name__ == "__main__":
    main()
