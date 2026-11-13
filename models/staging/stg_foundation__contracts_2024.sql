-- The same CRM list as exported on 2024-01-05 (active slots only, fewer columns).
select
    org_key,
    is_internal_test,
    vin_key,
    device_key,
    prev_device_key,
    make,
    model_year,
    cast(contract_date as date)     as contract_date,
    cast(activation_date as date)   as term_start_date,
    cast(expiration_date as date)   as term_end_date,
    cast(snapshot_date as date)     as export_date
from {{ source('contract_history', 'contracts_snapshot_2024_01_05') }}
