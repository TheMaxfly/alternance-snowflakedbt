select
    pickup_location_id,
    count(*) as total_trips,
    round(avg(trip_duration_minutes), 2) as avg_duration_min,
    round(avg(avg_speed_mph), 2) as avg_speed_mph,
    round(avg(trip_distance), 2) as avg_distance
from fact_trips
group by pickup_location_id
order by avg_duration_min desc
limit 15
