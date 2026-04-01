select
    pickup_hour,
    sum(total_trips) as total_trips,
    round(avg(avg_revenue), 2) as avg_revenue,
    round(avg(avg_speed_mph), 2) as avg_speed_mph
from hourly_patterns
group by 1
order by 1
