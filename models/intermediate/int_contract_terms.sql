-- Customer contract rows with the CRM's semantics made explicit.
--
-- The CRM keeps one row per vehicle subscription slot and overwrites the term dates in place at every
-- renewal, so term_start_date is the start of the current term (not the day the device went live) and
-- the number of renewals a slot has been through is round((term_start_date - contract_date) / 365).
-- Placeholder dates are nulled and flagged rather than dropped; the end of paid coverage is the term end
-- or the earlier return date when the device went back mid-term.
{% set term_days = 365 %}
{% set grace_days = 30 %}

with customer_rows as (
    select *
    from {{ ref('stg_foundation__contracts') }}
    where not is_internal_test
),

flagged as (
    select
        *,
        term_end_date > date '2030-12-31'                                               as flag_far_future_expiration,
        return_date is not null and term_start_date is not null
            and return_date < term_start_date                                           as flag_return_before_activation,
        vehicle_limit < 0                                                               as flag_negative_vehicle_limit,
        term_start_date > export_date                                                   as flag_activation_after_snapshot,
        status = 'active' and term_end_date < export_date                               as flag_active_past_expiration,
        contract_date is null and term_start_date is null                               as flag_missing_dates
    from customer_rows
),

cleaned as (
    select
        contract_row_id,
        org_key,
        dot_key,
        vin_key,
        device_key,
        prev_device_key,
        make,
        model_year,
        status,
        sales_rep_key,
        export_date,
        contract_date,
        term_start_date,
        case when flag_far_future_expiration then null else term_end_date end          as term_end_date,
        case when flag_return_before_activation then null else return_date end         as return_date,
        case when flag_negative_vehicle_limit then null else vehicle_limit end         as vehicle_limit,
        case when eld_type in ('rtha55', 'rtps47', 'rtel47', 'rtps12', 'rtoa47', 'rtsa12')
             then eld_type end                                                          as eld_type,
        flag_far_future_expiration,
        flag_return_before_activation,
        flag_negative_vehicle_limit,
        flag_activation_after_snapshot,
        flag_active_past_expiration,
        flag_missing_dates
    from flagged
),

derived as (
    select
        *,
        datediff('day', contract_date, term_start_date)                                 as term_gap_days,
        case
            when datediff('day', contract_date, term_start_date) < -14 then null
            else greatest(round(datediff('day', contract_date, term_start_date) / {{ term_days }}.0), 0)
        end                                                                             as renewals_so_far,
        eld_type = 'rtha55'                                                             as is_current_generation,
        prev_device_key is not null                                                     as is_replacement,
        coalesce(contract_date, term_start_date)                                        as slot_start_date,
        case when contract_date is not null then 'contract_date'
             when term_start_date is not null then 'term_start_date'
             else 'none' end                                                            as slot_start_source,
        status = 'deleted' and return_date is not null
            and return_date < coalesce(term_end_date, date '9999-12-31')               as is_early_return
    from cleaned
)

select
    *,
    abs(term_gap_days - renewals_so_far * {{ term_days }}) <= 7                         as gap_is_whole_years,
    case when is_early_return then return_date else term_end_date end                  as coverage_end_date,
    status = 'active'
        and (term_end_date is null or term_end_date >= export_date - interval {{ grace_days }} day) as is_active_now,
    status in ('inactive', 'unpaid', 'suspended') and term_end_date >= export_date     as is_billing_hold
from derived
