-- What happened to every customer subscription slot that was active in the January 2024 export by the
-- September 2026 export, read from the type-2 snapshot: renewed in place, renewed on a replacement device,
-- left to expire (row kept with the old dates), or purged from the CRM altogether.
with history as (
    select * from {{ ref('snap_subscription_slot') }}
),
v2024 as (
    select * from history where dbt_valid_from = date '2024-01-05'
),
v2026 as (
    select * from history where dbt_valid_from = date '2026-09-28'
),
outcome as (
    select
        a.slot_key,
        a.org_key,
        case
            when b.dbt_is_deleted = 'True'                                   then 'purged_from_crm'
            when b.term_start_date > a.term_start_date and b.device_key = a.device_key then 'renewed_same_device'
            when b.term_start_date > a.term_start_date                       then 'renewed_replacement_device'
            when b.term_start_date = a.term_start_date and b.status <> 'active' then 'expired_row_kept'
            when b.term_start_date = a.term_start_date                       then 'unchanged_still_active'
            when b.term_start_date is null                                   then 'term_dates_missing_in_2026'
            when b.term_start_date < a.term_start_date                       then 'term_start_moved_back'
            else 'other'
        end                                                                 as outcome,
        a.term_end_date                                                     as term_end_2024,
        b.term_start_date                                                   as term_start_2026,
        b.status                                                            as status_2026
    from v2024 a
    left join v2026 b using (slot_key)
)
select
    outcome,
    count(*)                                            as slots,
    count(*) / cast(sum(count(*)) over () as double)    as share_of_slots,
    count(distinct org_key)                             as organizations
from outcome
group by outcome
order by slots desc
