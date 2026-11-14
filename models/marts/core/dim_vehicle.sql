-- One row per VIN as registered in the driver-app back office (current registration), with the device and
-- organisation it belongs to today and how many times the VIN has been registered.
select
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
    vehicle_status,
    registrations,
    last_synced_ts
from {{ ref('int_vehicle_current_registration') }}
