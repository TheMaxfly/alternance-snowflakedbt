select
    time_period,
    count(*) as total_trips,
    round(avg(avg_speed_mph), 2) as avg_speed_mph,
    round(avg(trip_duration_minutes), 2) as avg_duration_min,
    round(avg(trip_distance), 2) as avg_distance
from fact_trips
group by time_period
order by total_trips desc
