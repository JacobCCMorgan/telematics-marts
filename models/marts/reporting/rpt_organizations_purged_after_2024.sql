-- Organisations that were active in the January 2024 export and have no dated contract row left in the
-- September 2026 export: the CRM purged them, and with them the record of when they left. This is the
-- organisation-level view of the slot purge in rpt_subscription_slot_changes and the figure the
-- subscription-lifecycle project restores its churn history from.
with orgs_2024 as (
    select distinct org_key
    from {{ ref('stg_foundation__contracts_2024') }}
    where not is_internal_test
),
dated_2026 as (
    select distinct org_key
    from {{ ref('int_contract_terms') }}
    where slot_start_date is not null
)
select
    count(*)                                                            as organizations_active_2024,
    count(*) filter (where d.org_key is null)                           as organizations_purged,
    count(*) filter (where d.org_key is null) / cast(count(*) as double) as purged_share
from orgs_2024 o
left join dated_2026 d using (org_key)
