-- One row per telemetry report flagged by at least one field-anomaly rule on 2026-09-28.
select
    cast(report_date as date) as report_date,
    report_ts,
    org_group               as batch_label,
    device_key,
    driver_key,
    vin_key,
    is_placeholder_vin,
    speed_kmh,
    rpm,
    engine_hours,
    engine_miles,
    car_battery_connected,
    gps_speed_kmh,
    lat_coarse,
    lon_coarse,
    vin_anomaly,
    speed_anomaly,
    rpm_anomaly,
    engine_hours_anomaly,
    engine_miles_anomaly
from {{ source('foundation', 'fact_field_anomaly') }}
