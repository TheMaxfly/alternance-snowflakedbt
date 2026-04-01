select
    pickup_hour,
    pickup_day_of_week_num,
    min(pickup_day_name) as pickup_day_name,
    min(time_period) as time_period,
    min(day_type) as day_type,
    count(*) as total_trips,
    round(avg(total_amount), 2) as avg_revenue,
    round(avg(trip_distance), 2) as avg_distance,
    round(avg(avg_speed_mph), 2) as avg_speed_mph,
    round(avg(tip_percentage), 2) as avg_tip_pct
from {{ ref('fact_trips') }}
group by pickup_hour, pickup_day_of_week_num
