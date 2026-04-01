select
    payment_type_label,
    count(*) as total_trips,
    round(avg(taux_pourboire), 2) as avg_taux_pourboire_pct,
    round(avg(total_amount), 2) as avg_revenue_per_trip,
    round(avg(tip_amount), 2) as avg_tip_amount
from fact_trips
group by payment_type_label
order by total_trips desc
