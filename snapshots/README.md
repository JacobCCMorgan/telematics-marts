# Snapshots

`snap_subscription_slot` is a type-2 history of customer subscription slots (organisation x VIN). The CRM
keeps one row per slot and overwrites the term dates at every renewal, so the only way to see what a slot
looked like before is an older export. Two exports exist in this repository (5 Jan 2024 and 28 Sep 2026);
the snapshot is built by running them in date order:

```bash
DBT_PROFILES_DIR=. dbt build --select +snap_subscription_slot --indirect-selection cautious --vars '{"contract_export": "2024-01-05"}'
DBT_PROFILES_DIR=. dbt build --select +snap_subscription_slot --indirect-selection cautious --vars '{"contract_export": "2026-09-28"}'
```

`scripts/build.sh` does this before `dbt build`. Running the snapshot again with the same export is a
no-op, so a plain `dbt build` afterwards (which runs the snapshot with the default `contract_export`) does
not add rows.

A slot present in the 2024 export and missing in 2026 was purged by the CRM; the snapshot records it as a
deletion row (`dbt_is_deleted = 'True'`, valid from 2026-09-28). The reporting mart
`rpt_subscription_slot_changes` summarises renewed, unchanged, replaced and purged slots.
