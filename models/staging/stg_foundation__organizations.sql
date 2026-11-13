select
    org_key,
    is_internal_test,
    crm_active,
    state,
    dot_key,
    has_dot,
    email_is_free_domain,
    crm_account_limit,
    crm_vehicle_limit,
    is_reseller,
    sales_rep_key,
    in_crm,
    in_app,
    in_contracts,
    app_fleet_vehicles,
    app_vehicle_limit
from {{ source('foundation', 'dim_org') }}
