-- One row per customer subscription slot (organisation x VIN) as it appeared in ONE export of the CRM
-- contract list. Which export is chosen by the `contract_export` variable:
--   2024-01-05  the earlier export (active slots only)
--   2026-09-28  the foundation export (all rows; a slot with several rows keeps its current one)
-- The subscription-slot snapshot reads this model once per export, oldest first, to build the SCD2 history
-- the CRM itself does not keep.
{% set export = var('contract_export') %}

{% if export == '2024-01-05' %}

select
    concat_ws('|', org_key, vin_key)    as slot_key,
    org_key,
    vin_key,
    device_key,
    prev_device_key,
    make,
    model_year,
    contract_date,
    term_start_date,
    term_end_date,
    'active'                            as status,
    export_date
from {{ ref('stg_foundation__contracts_2024') }}
where not is_internal_test
qualify row_number() over (partition by org_key, vin_key order by term_start_date desc nulls last, device_key) = 1

{% else %}

select
    concat_ws('|', org_key, vin_key)    as slot_key,
    org_key,
    vin_key,
    device_key,
    prev_device_key,
    make,
    model_year,
    contract_date,
    term_start_date,
    term_end_date,
    status,
    export_date
from {{ ref('int_contract_terms') }}
where vin_key is not null
qualify row_number() over (
    partition by org_key, vin_key
    order by case when status = 'active' then 0 when status in ('inactive', 'unpaid', 'suspended') then 1 else 2 end,
             term_start_date desc nulls last, contract_row_id desc
) = 1

{% endif %}
