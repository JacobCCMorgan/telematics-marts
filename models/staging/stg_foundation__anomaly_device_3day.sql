-- One row per device flagged on 23-25 Sep 2026 under "vehicle battery connected and GPS speed > 0",
-- with the three days' counts side by side as the rules engine exports them (counts cast to integers;
-- a day the device was not flagged is null).
select
    device_key,
    org_group                               as batch_label,
    cast(days_present as integer)           as days_present,
    cast(n_records as integer)              as reports_3day,
    cast(vin_missing_n as integer)          as vin_missing_3day,
    cast(speed_na_n as integer)             as speed_missing_3day,
    cast(rpm_na_n as integer)               as rpm_missing_3day,
    cast(all_three_missing_n as integer)    as all_three_missing_3day,
    cast(d0923_n_records as integer) as d0923_n_records, cast(d0923_vin_missing_n as integer) as d0923_vin_missing_n,
    cast(d0923_speed_na_n as integer) as d0923_speed_na_n, cast(d0923_rpm_na_n as integer) as d0923_rpm_na_n,
    cast(d0924_n_records as integer) as d0924_n_records, cast(d0924_vin_missing_n as integer) as d0924_vin_missing_n,
    cast(d0924_speed_na_n as integer) as d0924_speed_na_n, cast(d0924_rpm_na_n as integer) as d0924_rpm_na_n,
    cast(d0925_n_records as integer) as d0925_n_records, cast(d0925_vin_missing_n as integer) as d0925_vin_missing_n,
    cast(d0925_speed_na_n as integer) as d0925_speed_na_n, cast(d0925_rpm_na_n as integer) as d0925_rpm_na_n,
    first_seen_ts,
    last_seen_ts,
    last_valid_vin_ts,
    last_valid_vin_key
from {{ source('foundation', 'fact_anomaly_device_3day') }}
