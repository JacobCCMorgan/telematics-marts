select
    account_key,
    org_key,
    is_internal_test,
    license_state,
    license_shared_by_n_accounts,
    status          as account_status,
    country_raw     as country,
    last_synced_ts
from {{ source('foundation', 'dim_driver_account') }}
