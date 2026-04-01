select
    pickup_day_name,
    day_type,
    count(*) as total_trips,
    round(sum(total_amount), 2) as total_revenue,
    round(avg(total_amount), 2) as avg_revenue_per_trip,
    round(avg(taux_pourboire), 2) as avg_taux_pourboire_pct
from fact_trips
group by pickup_day_name, day_type
order by
    case pickup_day_name
        when 'Monday' then 1
        when 'Tuesday' then 2
        when 'Wednesday' then 3
        when 'Thursday' then 4
        when 'Friday' then 5
        when 'Saturday' then 6
        when 'Sunday' then 7
        else 8
    end
