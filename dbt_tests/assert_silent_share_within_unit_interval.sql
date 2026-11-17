-- Moving-while-silent shares are proportions: between 0 and 1 wherever a denominator exists.
select device_key, report_date, moving_silent_share
from {{ ref('fct_device_day') }}
where moving_silent_share < 0 or moving_silent_share > 1
   or (moving_reports > 0 and moving_silent_share is null)
