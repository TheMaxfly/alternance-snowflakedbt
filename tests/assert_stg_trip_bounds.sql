select *
from {{ ref('stg_yellow_taxi_trips') }}
where trip_distance not between 0.1 and 100
   or pickup_datetime >= dropoff_datetime
   or pickup_location_id is null
   or dropoff_location_id is null
   or fare_amount < 0
   or total_amount < 0
