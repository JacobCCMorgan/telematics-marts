-- Every slot active in the January 2024 export must be accounted for in the slot-change report.
with slots_2024 as (
    select count(*) as n from {{ ref('snap_subscription_slot') }} where dbt_valid_from = date '2024-01-05'
),
reported as (
    select sum(slots) as n from {{ ref('rpt_subscription_slot_changes') }}
)
select slots_2024.n as slots_2024, reported.n as reported
from slots_2024, reported
where slots_2024.n <> reported.n
