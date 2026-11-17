#!/usr/bin/env bash
# Full local build from an empty warehouse: the subscription-slot snapshot in export order (each run also
# rebuilds the models it depends on, because the export selector is a variable; cautious selection keeps the
# tests that also need the reporting marts for the final step), then every model, snapshot and test.
#
# The warehouse file is removed first. The snapshot is a replay of dated exports, oldest first: replaying the
# 2024 export onto a snapshot that already holds the 2026 one is recorded as a new change, not skipped, and
# leaves versions that overlap. A rebuild therefore always starts clean.
set -euo pipefail
cd "$(dirname "$0")/.."
export DBT_PROFILES_DIR=.
rm -f data/warehouse.duckdb data/warehouse.duckdb.wal
dbt build --select +snap_subscription_slot --indirect-selection cautious --vars '{"contract_export": "2024-01-05"}'
dbt build --select +snap_subscription_slot --indirect-selection cautious --vars '{"contract_export": "2026-09-28"}'
dbt build
