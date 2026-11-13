select
    device_key,
    org_group           as batch_label,
    sim_service_status,
    quota_status,
    remaining_data_mb,
    remaining_days,
    expiry_date         as sim_expiry_date,
    last_updated_ts     as sim_last_updated_ts
from {{ source('foundation', 'dim_sim') }}
