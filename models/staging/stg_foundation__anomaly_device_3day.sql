-- One row per device flagged on 23-25 Sep 2026 under "vehicle battery connected and GPS speed > 0",
-- with the three days' counts side by side as the rules engine exports them.
select
    device_key,
    org_group           as batch_label,
    days_present,
    n_records           as reports_3day,
    vin_missing_n       as vin_missing_3day,
    speed_na_n          as speed_missing_3day,
    rpm_na_n            as rpm_missing_3day,
    all_three_missing_n as all_three_missing_3day,
    d0923_n_records, d0923_vin_missing_n, d0923_speed_na_n, d0923_rpm_na_n,
    d0924_n_records, d0924_vin_missing_n, d0924_speed_na_n, d0924_rpm_na_n,
    d0925_n_records, d0925_vin_missing_n, d0925_speed_na_n, d0925_rpm_na_n,
    first_seen_ts,
    last_seen_ts,
    last_valid_vin_ts,
    last_valid_vin_key
from {{ source('foundation', 'fact_anomaly_device_3day') }}
