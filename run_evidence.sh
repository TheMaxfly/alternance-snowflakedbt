#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
EVIDENCE_DIR="${SCRIPT_DIR}/evidence"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Create it from .env.example first." >&2
  exit 1
fi

if [[ ! -d "${EVIDENCE_DIR}" ]]; then
  echo "Missing ${EVIDENCE_DIR}. Install Evidence first." >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  cat >&2 <<'EOF'
Usage: ./run_evidence.sh <npm-script> [args...]

Examples:
  ./run_evidence.sh sources
  ./run_evidence.sh dev
  ./run_evidence.sh build
EOF
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

export EVIDENCE_SOURCE__nyc_taxi__account="${SNOWFLAKE_ACCOUNT}"
export EVIDENCE_SOURCE__nyc_taxi__username="${SNOWFLAKE_USER}"
export EVIDENCE_SOURCE__nyc_taxi__password="${SNOWFLAKE_PASSWORD}"
export EVIDENCE_SOURCE__nyc_taxi__database="${SNOWFLAKE_DATABASE}"
export EVIDENCE_SOURCE__nyc_taxi__warehouse="${SNOWFLAKE_WAREHOUSE}"
export EVIDENCE_SOURCE__nyc_taxi__role="${SNOWFLAKE_ROLE:-ACCOUNTADMIN}"
export EVIDENCE_SOURCE__nyc_taxi__schema="FINAL"

cd "${EVIDENCE_DIR}"
exec npm run "$@"
