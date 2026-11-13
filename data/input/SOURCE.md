# Input tables: provenance

Every table in this directory is a de-identified derivative of one ELD / fleet-telematics provider's
operational data (device-management system, driver-app back office, CRM). Identifiers are keyed pseudonyms
(`DEV-`, `VIN-`, `ORG-`, `DOT-`, `DRV-`, `USR-`, `REP-`), coordinates are coarsened to about 5 km, and no
names, contact details, free text or payment fields are present. The key is not in this repository. The
same key was used across the portfolio, so the tables join to every other repository in
[`fleet-data-lab`](https://github.com/JacobCCMorgan/fleet-data-lab).

| file | rows | grain | copied from |
|---|---:|---|---|
| `dim_device.parquet` | 4,970 | ELD unit (registry snapshot, 28 Sep 2026) | [`telematics-data-foundation`](https://github.com/JacobCCMorgan/telematics-data-foundation) `data/public`, commit `cb55e5a` |
| `dim_sim.parquet` | 4,970 | SIM | same |
| `dim_vehicle.parquet` | 3,525 | vehicle (driver-app master) | same |
| `dim_driver_account.parquet` | 4,604 | driver login account | same |
| `dim_org.parquet` | 5,675 | customer organisation (CRM, app and contract rows merged) | same |
| `fact_contract.parquet` | 13,759 | vehicle subscription slot as of 28 Sep 2026 | same |
| `fact_anomaly_device_3day.parquet` | 215 | device flagged by the anomaly rules on 23-25 Sep 2026 | same |
| `fact_field_anomaly.parquet` | 51,858 | flagged telemetry report, 28 Sep 2026 | same |
| `contracts_snapshot_2024-01-05.parquet` | 4,977 | *active* vehicle subscription slot as of 5 Jan 2024 | [`eld-subscription-lifecycle`](https://github.com/JacobCCMorgan/eld-subscription-lifecycle) `data/input`, commit `f954352` |

The files are copied unchanged; column definitions are in the foundation's
[data dictionary](https://github.com/JacobCCMorgan/telematics-data-foundation/blob/main/data/public/DATA_DICTIONARY.md).
The January 2024 export is what the same CRM list looked like two and a half years earlier; the CRM
overwrites term dates at renewal and purges rows of customers who leave, which is why a point-in-time
snapshot is modelled here (see `snapshots/`).

Numbers derived from these tables describe one provider's fleet at the stated export dates. They are not
statements about the industry or about the provider's current commercial performance.
