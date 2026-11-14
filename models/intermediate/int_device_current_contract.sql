-- One row per device that appears in the contract list: its current subscription row (an active row first,
-- otherwise the latest term start), carrying the organisation, the hardware generation code and the status.
with ranked as (
    select
        *,
        row_number() over (
            partition by device_key
            order by case when status = 'active' then 0 when status in ('inactive', 'unpaid', 'suspended') then 1 else 2 end,
                     term_start_date desc nulls last, contract_row_id desc
        ) as rn
    from {{ ref('int_contract_terms') }}
    where device_key is not null
)
select * exclude (rn)
from ranked
where rn = 1
