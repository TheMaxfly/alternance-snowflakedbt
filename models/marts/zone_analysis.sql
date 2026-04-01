select
    pickup_location_id,
    count(*) as total_trips,
    round(avg(total_amount), 2) as avg_revenue,
    round(sum(total_amount), 2) as total_revenue,
    round(avg(trip_distance), 2) as avg_distance,
    round(avg(trip_duration_minutes), 2) as avg_duration_min,
    round(avg(avg_speed_mph), 2) as avg_speed_mph,
    round(avg(tip_percentage), 2) as avg_tip_pct,
    count(distinct pickup_date) as active_days,
    round(100.0 * avg(case when day_type = 'weekend' then 1 else 0 end), 2) as weekend_trip_share_pct
from {{ ref('fact_trips') }}
group by pickup_location_id
