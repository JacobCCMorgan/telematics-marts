# Snapshots

`snap_subscription_slot` is a type-2 history of customer subscription slots (organisation x VIN). The CRM
keeps one row per slot and overwrites the term dates at every renewal, so the only way to see what a slot
looked like before is an older export. Two exports exist in this repository (5 Jan 2024 and 28 Sep 2026);
the snapshot is built by running them in date order:

```bash
DBT_PROFILES_DIR=. dbt build --select +snap_subscription_slot --indirect-selection cautious --vars '{"contract_export": "2024-01-05"}'
DBT_PROFILES_DIR=. dbt build --select +snap_subscription_slot --indirect-selection cautious --vars '{"contract_export": "2026-09-28"}'
```

`scripts/build.sh` does this before `dbt build`. Running the snapshot again with the latest export is a
no-op, so a plain `dbt build` afterwards (which runs the snapshot with the default `contract_export`) does
not add rows.

The order matters and the replay is not repeatable in place. Running the 2024 export against a snapshot
that already holds 2026 closes the current versions as of 2024 and writes the 2024 rows again: 19,010 rows
become 33,061, and `assert_snapshot_versions_do_not_overlap` fails. `scripts/build.sh` removes
`data/warehouse.duckdb` before it starts, so every build replays both exports onto an empty snapshot.

A slot present in the 2024 export and missing in 2026 was purged by the CRM; the snapshot records it as a
deletion row (`dbt_is_deleted = 'True'`, valid from 2026-09-28). The reporting mart
`rpt_subscription_slot_changes` summarises renewed, unchanged, replaced and purged slots.
