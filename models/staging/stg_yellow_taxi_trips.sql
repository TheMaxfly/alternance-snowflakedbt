with source_data as (
    select * from {{ source('raw', 'yellow_taxi_trips') }}
),

converted as (
    select
        "VendorID" as vendor_id,
        to_timestamp_ntz("tpep_pickup_datetime", 6) as pickup_datetime,
        to_timestamp_ntz("tpep_dropoff_datetime", 6) as dropoff_datetime,
        "passenger_count" as passenger_count,
        "trip_distance" as trip_distance,
        "RatecodeID" as ratecode_id,
        "store_and_fwd_flag" as store_and_fwd_flag,
        "PULocationID" as pickup_location_id,
        "DOLocationID" as dropoff_location_id,
        "payment_type" as payment_type,
        "fare_amount" as fare_amount,
        "extra" as extra,
        "mta_tax" as mta_tax,
        "tip_amount" as tip_amount,
        "tolls_amount" as tolls_amount,
        "improvement_surcharge" as improvement_surcharge,
        "total_amount" as total_amount,
        "congestion_surcharge" as congestion_surcharge,
        "Airport_fee" as airport_fee,
        "cbd_congestion_fee" as cbd_congestion_fee,
        _SOURCE_FILE as source_file,
        _LOADED_AT as loaded_at
    from source_data
)

select
    vendor_id,
    pickup_datetime,
    dropoff_datetime,
    cast(pickup_datetime as date) as pickup_date,
    cast(dropoff_datetime as date) as dropoff_date,
    hour(pickup_datetime) as pickup_hour,
    dayofweek(pickup_datetime) as pickup_day_of_week_num,
    case dayofweek(pickup_datetime)
        when 0 then 'Sunday'
        when 1 then 'Monday'
        when 2 then 'Tuesday'
        when 3 then 'Wednesday'
        when 4 then 'Thursday'
        when 5 then 'Friday'
        when 6 then 'Saturday'
    end as pickup_day_name,
    month(pickup_datetime) as pickup_month,
    year(pickup_datetime) as pickup_year,
    passenger_count,
    trip_distance,
    ratecode_id,
    store_and_fwd_flag,
    pickup_location_id,
    dropoff_location_id,
    payment_type,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    airport_fee,
    cbd_congestion_fee,
    source_file,
    loaded_at
from converted
where fare_amount >= 0
  and total_amount >= 0
  and pickup_datetime < dropoff_datetime
  and trip_distance between 0.1 and 100
  and pickup_location_id is not null
  and dropoff_location_id is not null
  and datediff('minute', pickup_datetime, dropoff_datetime) between 1 and 300
