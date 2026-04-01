select
    pickup_location_id,
    total_trips,
    total_revenue,
    avg_revenue,
    avg_distance,
    avg_taux_pourboire_pct
from zone_analysis
order by total_trips desc
limit 10
