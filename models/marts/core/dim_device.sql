-- One row per ELD unit: registry state at the 2026-09-28 snapshot, its SIM, the vehicle and organisation
-- it is registered to, and its current subscription row.
with devices as (
    select * from {{ ref('stg_foundation__devices') }}
),
sims as (
    select * from {{ ref('stg_foundation__sims') }}
),
vehicles as (
    select * from {{ ref('int_device_current_vehicle') }}
),
contracts as (
    select * from {{ ref('int_device_current_contract') }}
)

select
    d.device_key,
    d.is_internal_test,
    d.batch_label,
    d.hw_generation,
    d.model_code,
    d.fw_version,
    d.st_fw_version,
    d.ble_fw_version,
    d.never_reported,
    d.connect_status,
    d.last_mode,
    d.last_mode = 'LowBattery'                                                     as last_reported_low_battery,
    d.backup_battery_pct,
    d.car_battery_connected,
    d.gps_valid,
    d.mileage_source_sa,
    d.report_ts                                                                    as last_report_ts,
    d.last_updated_ts,
    datediff('day', cast(d.last_updated_ts as date), cast('{{ var("snapshot_date") }}' as date)) as days_since_last_update,
    d.engine_hours,
    d.engine_miles,
    d.vin_key                                                                      as registry_vin_key,
    d.is_placeholder_vin                                                           as registry_vin_is_placeholder,
    d.vehicle_make                                                                 as registry_vehicle_make,
    d.vehicle_year                                                                 as registry_vehicle_year,
    v.vin_key                                                                      as vehicle_vin_key,
    v.org_key,
    v.make                                                                         as vehicle_make,
    v.model_year                                                                   as vehicle_model_year,
    v.vehicle_status,
    c.contract_row_id                                                              as current_contract_row_id,
    c.eld_type                                                                     as contract_eld_type,
    c.is_current_generation                                                        as contract_is_current_generation,
    c.status                                                                       as contract_status,
    c.is_active_now                                                                as contract_is_active_now,
    s.sim_service_status,
    s.quota_status,
    s.remaining_data_mb                                                            as sim_remaining_data_mb,
    s.remaining_days                                                               as sim_remaining_days,
    s.sim_expiry_date
from devices d
left join sims s using (device_key)
left join vehicles v on v.device_key = d.device_key
left join contracts c on c.device_key = d.device_key
