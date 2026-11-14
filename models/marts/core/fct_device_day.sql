-- One row per device-day of moving-while-silent telemetry (see int_device_day_anomaly), with the device's
-- test flag and batch, and the severity flag used by the ECM-disconnect project (at least 20 silent
-- moving reports in a day, about ten minutes at the 30-second cadence).
select
    a.device_key,
    a.report_date,
    a.source_table,
    coalesce(d.is_internal_test, false)         as is_internal_test,
    d.batch_label,
    d.hw_generation,
    a.moving_reports,
    a.flagged_reports,
    a.moving_silent_reports,
    a.speed_missing_reports,
    a.vin_missing_reports,
    a.moving_silent_share,
    a.moving_silent_reports >= 20               as is_severe_day
from {{ ref('int_device_day_anomaly') }} a
left join {{ ref('stg_foundation__devices') }} d using (device_key)
