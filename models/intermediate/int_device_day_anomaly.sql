-- One row per device-day of "moving while silent" telemetry: the truck reports GPS motion while the ELD
-- has no engine speed (RPM) from the engine computer.
--
-- 23-25 Sep 2026 come from the rules engine's three-day summary, which carries per-day counts side by
-- side and a denominator (all reports under "battery connected and GPS speed > 0"). 28 Sep comes from the
-- report-level anomaly file, which holds only flagged reports, so its denominator is unknown (null).
with three_day as (
    select * from {{ ref('stg_foundation__anomaly_device_3day') }}
),

unpivoted as (
    select device_key, date '2026-09-23' as report_date, d0923_n_records as moving_reports,
           d0923_rpm_na_n as moving_silent_reports, d0923_speed_na_n as speed_missing_reports, d0923_vin_missing_n as vin_missing_reports
    from three_day
    union all
    select device_key, date '2026-09-24', d0924_n_records, d0924_rpm_na_n, d0924_speed_na_n, d0924_vin_missing_n from three_day
    union all
    select device_key, date '2026-09-25', d0925_n_records, d0925_rpm_na_n, d0925_speed_na_n, d0925_vin_missing_n from three_day
),

window_days as (
    select
        device_key,
        report_date,
        'three_day_summary'                     as source_table,
        cast(moving_reports as integer)         as moving_reports,
        cast(null as integer)                   as flagged_reports,
        cast(moving_silent_reports as integer)  as moving_silent_reports,
        cast(speed_missing_reports as integer)  as speed_missing_reports,
        cast(vin_missing_reports as integer)    as vin_missing_reports
    from unpivoted
    where coalesce(moving_reports, 0) > 0
),

anomaly_day as (
    select
        device_key,
        report_date,
        'anomaly_reports'                                                       as source_table,
        cast(null as integer)                                                   as moving_reports,
        count(*)                                                                as flagged_reports,
        count(*) filter (where rpm_anomaly and gps_speed_kmh > 0)               as moving_silent_reports,
        count(*) filter (where speed_anomaly and gps_speed_kmh > 0)             as speed_missing_reports,
        count(*) filter (where vin_anomaly and gps_speed_kmh > 0)               as vin_missing_reports
    from {{ ref('stg_foundation__anomaly_reports') }}
    group by device_key, report_date
)

select
    *,
    case when moving_reports > 0 then moving_silent_reports / moving_reports end as moving_silent_share
from window_days
union all
select
    *,
    cast(null as double) as moving_silent_share
from anomaly_day
