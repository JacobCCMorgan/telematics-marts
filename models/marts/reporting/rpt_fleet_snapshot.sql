-- The fleet-snapshot headline metrics as a long table (one row per metric), defined once here so that the
-- README of the foundation repository, dashboards and interview answers quote the same numbers. All
-- metrics exclude the provider's internal test units and organisations.
{% set snapshot_date = var('snapshot_date') %}

with customer_devices as (
    select * from {{ ref('dim_device') }} where not is_internal_test
),
reporting as (
    select * from customer_devices where not never_reported
),
terms as (
    select * from {{ ref('fct_contract_term') }}
    where term_start_date is not null and term_end_date is not null
),
orgs as (
    select * from {{ ref('dim_organization') }} where not is_internal_test
),
metrics as (
    select 'registered_units' as metric, count(*) as value, null as denominator, 'ELD units in the device registry (customer)' as definition from customer_devices
    union all select 'never_reported_units', count(*) filter (where never_reported), count(*), 'registered units that have never sent telemetry (inventory, shipping)' from customer_devices
    union all select 'reporting_units', count(*), null, 'customer units that have reported at least once' from reporting
    union all select 'online_units', count(*) filter (where connect_status = 'Online'), count(*), 'reporting units whose connection status was Online at the snapshot' from reporting
    union all select 'last_reported_low_battery_units', count(*) filter (where last_reported_low_battery), count(*), 'reporting units whose last report was in LowBattery mode' from reporting
    union all select 'backup_battery_at_most_20pct_units', count(*) filter (where backup_battery_pct <= 20), count(*), 'reporting units at 20 % backup battery or less' from reporting
    union all select 'not_updated_over_30_days_units', count(*) filter (where days_since_last_update > 30), count(*), 'reporting units with no update for more than 30 days before the snapshot' from reporting
    union all select 'never_read_vin_units', count(*) filter (where registry_vin_key is null or registry_vin_is_placeholder), count(*), 'reporting units whose registry VIN is missing or a placeholder (the engine computer was never read)' from reporting
    union all select 'no_valid_gps_units', count(*) filter (where gps_valid = false), count(*), 'reporting units without a valid GPS fix at the last report' from reporting
    union all select 'contract_terms_exactly_365_days', count(*) filter (where datediff('day', term_start_date, term_end_date) = 365), count(*), 'contract rows whose current term is exactly 365 days' from terms
    union all select 'organizations_active', count(*) filter (where lifecycle_status = 'active'), count(*) filter (where lifecycle_status <> 'never_contracted'), 'organisations with at least one active subscription, among those that ever had a contract row' from orgs
    union all select 'organizations_lapsed', count(*) filter (where lifecycle_status = 'lapsed'), count(*) filter (where lifecycle_status <> 'never_contracted'), 'organisations whose last coverage ended more than 30 days before the snapshot' from orgs
)
select
    cast('{{ snapshot_date }}' as date)                     as snapshot_date,
    metric,
    value,
    denominator,
    case when denominator > 0 then value / cast(denominator as double) end as share,
    definition
from metrics
