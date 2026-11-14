-- One row per device that appears in the vehicle master: the registration that holds the device today
-- (an active row first, otherwise the most recently synced one). A device that was moved between trucks
-- appears on several registrations; only one can be current.
with ranked as (
    select
        *,
        row_number() over (
            partition by device_key
            order by case when vehicle_status = 'active' then 0 else 1 end, last_synced_ts desc nulls last, registration_id
        ) as rn
    from {{ ref('stg_foundation__vehicles') }}
    where device_key is not null
)
select * exclude (rn)
from ranked
where rn = 1
