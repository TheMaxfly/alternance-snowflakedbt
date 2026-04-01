#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Create it from .env.example first." >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  cat >&2 <<'EOF'
Usage: ./run_dbt.sh <dbt-command> [args...]

Examples:
  ./run_dbt.sh debug
  ./run_dbt.sh run
  ./run_dbt.sh test
  ./run_dbt.sh docs generate
  ./run_dbt.sh docs serve
EOF
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

export UV_CACHE_DIR="${UV_CACHE_DIR:-/tmp/uv-cache}"

if [[ "${1}" == -* ]]; then
  exec uv run dbt "$@"
fi

exec uv run dbt "$@" --project-dir "${SCRIPT_DIR}" --profiles-dir "${SCRIPT_DIR}"
