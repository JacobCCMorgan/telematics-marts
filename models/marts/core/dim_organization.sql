-- One row per customer organisation: CRM and app attributes from the foundation plus the subscription
-- lifecycle derived from the cleaned contract rows (customer organisations only carry contract metrics).
{% set grace_days = 30 %}

with orgs as (
    select * from {{ ref('stg_foundation__organizations') }}
),
terms as (
    select
        org_key,
        count(*)                                                        as subscription_rows,
        count(distinct vin_key)                                         as vehicles_ever,
        count(*) filter (where is_active_now)                           as active_subscriptions,
        count(*) filter (where is_billing_hold)                         as subscriptions_on_billing_hold,
        count(*) filter (where is_active_now and is_current_generation) as active_current_generation,
        min(slot_start_date)                                            as first_contract_date,
        max(coverage_end_date)                                          as last_coverage_end_date,
        bool_or(is_active_now and term_end_date is null)                as has_open_ended_active_row,
        max(export_date)                                                as export_date
    from {{ ref('int_contract_terms') }}
    group by org_key
)

select
    o.org_key,
    o.is_internal_test,
    o.state,
    o.has_dot,
    o.dot_key,
    o.is_reseller,
    o.crm_active,
    o.in_crm,
    o.in_app,
    o.in_contracts,
    o.app_fleet_vehicles,
    o.crm_vehicle_limit,
    o.sales_rep_key,
    t.subscription_rows,
    t.vehicles_ever,
    t.active_subscriptions,
    t.subscriptions_on_billing_hold,
    t.active_current_generation,
    t.first_contract_date,
    t.last_coverage_end_date,
    case
        when t.org_key is null then 'never_contracted'
        when t.active_subscriptions > 0 then 'active'
        when t.last_coverage_end_date is null then 'no_dates'
        when t.last_coverage_end_date >= t.export_date - interval {{ grace_days }} day then 'in_grace_period'
        else 'lapsed'
    end                                                                             as lifecycle_status,
    case when t.org_key is not null
         then datediff('day', t.first_contract_date,
                       least(coalesce(t.last_coverage_end_date, t.export_date), t.export_date)) end as tenure_days
from orgs o
left join terms t using (org_key)
