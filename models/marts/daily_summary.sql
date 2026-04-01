select
    pickup_date,
    min(pickup_year) as pickup_year,
    min(pickup_month) as pickup_month,
    count(*) as total_trips,
    round(avg(trip_distance), 2) as avg_distance_miles,
    round(avg(trip_duration_minutes), 1) as avg_duration_min,
    round(avg(avg_speed_mph), 2) as avg_speed_mph,
    round(sum(total_amount), 2) as total_revenue,
    round(avg(total_amount), 2) as avg_revenue_per_trip,
    round(avg(taux_pourboire), 2) as avg_taux_pourboire_pct,
    sum(passenger_count) as total_passengers,
    round(100.0 * avg(case when day_type = 'weekend' then 1 else 0 end), 2) as weekend_trip_share_pct
from {{ ref('fact_trips') }}
group by pickup_date
