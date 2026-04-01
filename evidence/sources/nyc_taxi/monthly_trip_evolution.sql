select
    date_trunc('month', pickup_date) as mois,
    sum(total_trips) as total_trips,
    round(sum(total_revenue), 2) as total_revenue,
    round(avg(avg_revenue_per_trip), 2) as avg_revenue_per_trip
from daily_summary
group by 1
order by 1
