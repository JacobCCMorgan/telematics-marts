-- Type-2 rows of the same slot must not overlap: the previous version ends where the next begins.
with ordered as (
    select
        slot_key,
        dbt_valid_from,
        dbt_valid_to,
        lead(dbt_valid_from) over (partition by slot_key order by dbt_valid_from) as next_valid_from
    from {{ ref('snap_subscription_slot') }}
)
select *
from ordered
where next_valid_from is not null and (dbt_valid_to is null or dbt_valid_to <> next_valid_from)
