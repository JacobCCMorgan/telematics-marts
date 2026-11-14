-- One row per VIN: the registration that represents the vehicle today (an active row first, otherwise the
-- most recently synced one), with the number of registrations the VIN has had.
with ranked as (
    select
        *,
        count(*) over (partition by vin_key) as registrations,
        row_number() over (
            partition by vin_key
            order by case when vehicle_status = 'active' then 0 else 1 end, last_synced_ts desc nulls last, registration_id
        ) as rn
    from {{ ref('stg_foundation__vehicles') }}
)
select * exclude (rn)
from ranked
where rn = 1
