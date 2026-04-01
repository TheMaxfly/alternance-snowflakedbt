select *
from {{ ref('int_trip_metrics') }}
where trip_duration_minutes not between 1 and 300
   or avg_speed_mph < 0
   or (tip_percentage is not null and tip_percentage < 0)
