-- Online rate and low-battery share by hardware generation, reporting customer units only.
-- Descriptive: newer firmware ships on newer boards, so generation and firmware are confounded.
select
    hw_generation,
    count(*)                                                        as reporting_units,
    count(*) filter (where connect_status = 'Online')               as online_units,
    count(*) filter (where connect_status = 'Online') / cast(count(*) as double) as online_rate,
    count(*) filter (where last_reported_low_battery)               as low_battery_units,
    count(*) filter (where last_reported_low_battery) / cast(count(*) as double) as low_battery_share
from {{ ref('dim_device') }}
where not is_internal_test and not never_reported
group by hw_generation
order by hw_generation
