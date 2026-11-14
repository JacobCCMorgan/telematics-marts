-- One row per vehicle subscription slot as of the 2026-09-28 export, cleaned (see int_contract_terms),
-- with the hardware generation of the device on the row.
select
    t.*,
    d.hw_generation,
    d.batch_label
from {{ ref('int_contract_terms') }} t
left join {{ ref('stg_foundation__devices') }} d using (device_key)
