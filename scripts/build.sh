#!/usr/bin/env bash
# Full local build: the subscription-slot snapshot in export order (each run also rebuilds the models it
# depends on, because the export selector is a variable; cautious selection keeps the tests that also need
# the reporting marts for the final step), then every model, snapshot and test.
set -euo pipefail
cd "$(dirname "$0")/.."
export DBT_PROFILES_DIR=.
dbt build --select +snap_subscription_slot --indirect-selection cautious --vars '{"contract_export": "2024-01-05"}'
dbt build --select +snap_subscription_slot --indirect-selection cautious --vars '{"contract_export": "2026-09-28"}'
dbt build
