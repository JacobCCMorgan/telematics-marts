{#- The subscription-slot snapshot is replayed from dated CRM exports, so "now" for the snapshot is the
    export date, not the wall clock: a slot missing from an export is recorded as deleted as of that
    export. dbt uses this macro for the deletion records (the other versions take their dates from the
    updated_at column, export_date). -#}
{% macro duckdb__snapshot_get_time() -%}
    cast('{{ var("contract_export") }}' as date)
{%- endmacro %}
