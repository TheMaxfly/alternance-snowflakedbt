select
    pickup_location_id,
    total_trips,
    total_revenue,
    avg_revenue,
    avg_distance,
    avg_duration_min,
    avg_speed_mph,
    avg_taux_pourboire_pct
from zone_analysis
order by total_revenue desc
limit 15
