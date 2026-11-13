-- One row per vehicle *registration* in the driver-app back office: a VIN that was re-registered after a
-- device replacement or a change of customer appears more than once (old row deleted or inactive).
-- The marts collapse this to one row per VIN; the registration grain is kept here.
select
    md5(concat_ws('|', vin_key, org_key, coalesce(device_key, ''), coalesce(cast(last_synced_ts as varchar), ''))) as registration_id,
    vin_key,
    is_placeholder_vin,
    org_key,
    is_internal_test,
    device_key,
    driver_assigned,
    make,
    model,
    model_year,
    fuel_type,
    state,
    country,
    terminal_timezone,
    odometer_adjustment,
    status          as vehicle_status,
    last_synced_ts
from {{ source('foundation', 'dim_vehicle') }}
