-- One row per device flagged in the 23-25 Sep 2026 window: the rules engine's three-day totals, the
-- share-based severity class and the count-based tier that decides the field-visit order, plus what
-- happened on 28 Sep (day 4). Definitions follow the ECM-disconnect project so its results reproduce.
with three_day as (
    select
        device_key,
        days_present,
        reports_3day                                        as moving_reports_3day,
        rpm_missing_3day                                    as moving_silent_reports_3day,
        rpm_missing_3day / cast(reports_3day as double)     as moving_silent_share_3day
    from {{ ref('stg_foundation__anomaly_device_3day') }}
),
day4 as (
    select
        device_key,
        moving_silent_reports                               as moving_silent_reports_day4,
        is_severe_day                                       as is_severe_day4
    from {{ ref('fct_device_day') }}
    where source_table = 'anomaly_reports'
),
devices as (
    select
        device_key,
        is_internal_test,
        batch_label,
        hw_generation,
        cast(last_updated_ts as date) >= date '2026-09-28'  as reported_on_day4
    from {{ ref('stg_foundation__devices') }}
)

select
    w.device_key,
    coalesce(d.is_internal_test, false)                                             as is_internal_test,
    d.batch_label,
    d.hw_generation,
    w.days_present,
    w.moving_reports_3day,
    w.moving_silent_reports_3day,
    w.moving_silent_share_3day,
    case
        when w.days_present = 3 and w.moving_silent_share_3day >= 0.9 then 'chronic'
        when w.moving_silent_share_3day < 0.2 then 'transient'
        else 'intermittent'
    end                                                                             as severity_class,
    case
        when w.moving_silent_reports_3day > 1000 then 'P1'
        when w.moving_silent_reports_3day > 200  then 'P2'
        when w.moving_silent_reports_3day > 20   then 'P3'
        else 'P4'
    end                                                                             as priority_tier,
    d4.device_key is not null or coalesce(d.reported_on_day4, false)                as observed_day4,
    coalesce(d4.moving_silent_reports_day4, 0)                                      as moving_silent_reports_day4,
    coalesce(d4.moving_silent_reports_day4, 0) >= 1                                 as recurred_day4,
    coalesce(d4.is_severe_day4, false)                                              as is_severe_day4
from three_day w
left join devices d using (device_key)
left join day4 d4 using (device_key)
