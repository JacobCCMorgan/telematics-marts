{% snapshot snap_subscription_slot %}

{{
    config(
        unique_key='slot_key',
        strategy='check',
        check_cols=['term_start_date', 'term_end_date', 'device_key', 'status'],
        updated_at='export_date',
        hard_deletes='new_record'
    )
}}

-- Type-2 history of customer subscription slots across CRM exports. The CRM overwrites term dates in place
-- at every renewal and purges rows of customers who leave; running this snapshot once per export (oldest
-- first) keeps the versions the CRM discards. dbt_valid_from / dbt_valid_to carry the export dates, and a
-- slot that disappears between exports gets a deletion record (dbt_is_deleted = True).
select * from {{ ref('int_subscription_slot_export') }}

{% endsnapshot %}
