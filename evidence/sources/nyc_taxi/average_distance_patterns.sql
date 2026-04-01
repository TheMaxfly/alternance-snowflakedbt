select
    time_period,
    day_type,
    count(*) as total_trips,
    round(avg(trip_distance), 2) as avg_distance,
    round(avg(trip_duration_minutes), 2) as avg_duration_min
from fact_trips
group by time_period, day_type
order by time_period, day_type
