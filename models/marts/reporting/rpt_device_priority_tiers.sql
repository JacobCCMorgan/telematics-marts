-- The field-visit tiers of the ECM-disconnect project computed from the anomaly-window fact: how many
-- customer devices fall in each tier, how often they were severe again on 28 Sep, and what share of the
-- 28 Sep silent driving they produced.
with customer as (
    select * from {{ ref('fct_device_anomaly_window') }} where not is_internal_test
),
totals as (
    select sum(moving_silent_reports_day4) as silent_day4_total from customer
)
select
    c.priority_tier,
    case c.priority_tier
        when 'P1' then 'more than 1,000 silent moving reports in three days'
        when 'P2' then '201 to 1,000'
        when 'P3' then '21 to 200'
        else 'up to 20'
    end                                                                     as rule,
    count(*)                                                                as devices,
    count(*) filter (where observed_day4)                                   as observed_day4,
    count(*) filter (where is_severe_day4)                                  as severe_day4,
    count(*) filter (where is_severe_day4) / cast(nullif(count(*) filter (where observed_day4), 0) as double) as severe_day4_share,
    sum(c.moving_silent_reports_day4)                                       as silent_reports_day4,
    sum(c.moving_silent_reports_day4) / cast(t.silent_day4_total as double) as share_of_day4_silent_reports
from customer c
cross join totals t
group by c.priority_tier, t.silent_day4_total
order by c.priority_tier
