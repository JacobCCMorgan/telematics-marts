-- One row per vehicle subscription slot in the CRM list as exported on 2026-09-28.
-- The CRM overwrites term dates in place at every renewal: activation_date is the start of the
-- *current* term, expiration_date its end; contract_date is the date the slot was first sold.
select
    contract_row_id,
    org_key,
    is_internal_test,
    dot_key,
    vin_key,
    lower(eld_type)     as eld_type,
    device_key,
    prev_device_key,
    make,
    model_year,
    status,
    cast(contract_date as date)     as contract_date,
    cast(activation_date as date)   as term_start_date,
    cast(expiration_date as date)   as term_end_date,
    cast(return_date as date)       as return_date,
    vehicle_limit,
    sales_rep_key,
    cast('{{ var("snapshot_date") }}' as date) as export_date
from {{ source('foundation', 'fact_contract') }}
