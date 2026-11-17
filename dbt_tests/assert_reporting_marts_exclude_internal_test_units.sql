-- The provider's bench devices have no engine attached and must never reach the reporting marts:
-- the registered-unit count has to equal the number of customer devices in dim_device.
with reported as (
    select value from {{ ref('rpt_fleet_snapshot') }} where metric = 'registered_units'
),
expected as (
    select count(*) as value from {{ ref('dim_device') }} where not is_internal_test
)
select reported.value as reported, expected.value as expected
from reported, expected
where reported.value <> expected.value
