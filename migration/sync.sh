#!/usr/bin/env bash
# THE delta-sync. Run daily during the ~4-week transition window while old app
# versions keep writing to Firestore.
#
#   migration/sync.sh
#   ENV_FILE=/path/to/other.env migration/sync.sh    # e.g. point at a local stack
#
# All five steps share one RUN_TS so a run's exports and reports sit together
# and can be correlated afterwards. Any step failing aborts the chain (set -e):
# a half-applied sync that still reported success would be far worse than a
# loud failure, because the next day's run would build on top of it.

set -euo pipefail

: "${MIGRATION_DATA_DIR:?MIGRATION_DATA_DIR is not set. export it first — note ~/.zshrc is not read by cron or CI}"

ENV_FILE="${ENV_FILE:-$MIGRATION_DATA_DIR/.env}"
[ -f "$ENV_FILE" ] || { echo "ERROR: env file not found: $ENV_FILE" >&2; exit 1; }

export RUN_TS="${RUN_TS:-$(date -u +%Y-%m-%dT%H-%M-%SZ)}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load only what export_auth.sh needs directly (it shells out to the firebase
# CLI rather than reading the env file itself).
set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

echo "=============================================="
echo " delta-sync  RUN_TS=$RUN_TS"
echo " data dir:   $MIGRATION_DATA_DIR"
echo " env file:   $ENV_FILE"
echo "=============================================="

step() {
  echo ""
  echo "---> $1"
  shift
  "$@"
}

step "1/5 export Firebase Auth"   "$HERE/export_auth.sh"
step "2/5 export Firestore"       node --env-file="$ENV_FILE" "$HERE/export_firestore.ts"
step "3/5 import users"           node --env-file="$ENV_FILE" "$HERE/import_users.ts"
step "4/5 import data"            node --env-file="$ENV_FILE" "$HERE/import_data.ts"
step "5/5 validate"               node --env-file="$ENV_FILE" "$HERE/validate.ts"

echo ""
echo "=============================================="
echo " sync OK — reports in $MIGRATION_DATA_DIR/reports/$RUN_TS-*.json"
echo "=============================================="
