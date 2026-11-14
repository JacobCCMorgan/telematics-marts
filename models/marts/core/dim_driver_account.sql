-- One row per driver login account (the most recently synced row when the back office holds duplicates).
with ranked as (
    select
        *,
        row_number() over (partition by account_key order by last_synced_ts desc nulls last) as rn
    from {{ ref('stg_foundation__driver_accounts') }}
)
select
    account_key,
    org_key,
    is_internal_test,
    license_state,
    license_shared_by_n_accounts,
    license_shared_by_n_accounts > 1 as license_is_shared,
    account_status,
    country,
    last_synced_ts
from ranked
where rn = 1
