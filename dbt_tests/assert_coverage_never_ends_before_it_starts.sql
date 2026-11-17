-- A row's paid coverage cannot end before the term it belongs to started, except on the rows the CRM
-- itself holds with an expiration earlier than the term start (flagged in int_contract_terms, kept as data).
select contract_row_id, term_start_date, coverage_end_date
from {{ ref('fct_contract_term') }}
where coverage_end_date < term_start_date
  and not flag_term_end_before_start
