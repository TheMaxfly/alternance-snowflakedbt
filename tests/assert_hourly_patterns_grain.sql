select
    pickup_hour,
    pickup_day_of_week_num,
    count(*) as row_count
from {{ ref('hourly_patterns') }}
group by pickup_hour, pickup_day_of_week_num
having count(*) > 1
