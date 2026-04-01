with trips as (
    select * from {{ ref('stg_yellow_taxi_trips') }}
)

select
    md5(
        concat_ws(
            '|',
            coalesce(source_file, ''),
            to_varchar(pickup_datetime, 'YYYY-MM-DD HH24:MI:SS.FF6'),
            to_varchar(dropoff_datetime, 'YYYY-MM-DD HH24:MI:SS.FF6'),
            coalesce(to_varchar(vendor_id), ''),
            coalesce(to_varchar(pickup_location_id), ''),
            coalesce(to_varchar(dropoff_location_id), ''),
            coalesce(to_varchar(trip_distance), ''),
            coalesce(to_varchar(total_amount), '')
        )
    ) as trip_id,
    vendor_id,
    pickup_datetime,
    dropoff_datetime,
    pickup_date,
    pickup_hour,
    pickup_day_of_week_num,
    pickup_day_name,
    pickup_month,
    pickup_year,
    passenger_count,
    trip_distance,
    ratecode_id,
    store_and_fwd_flag,
    pickup_location_id,
    dropoff_location_id,
    payment_type,
    case payment_type
        when 1 then 'credit_card'
        when 2 then 'cash'
        when 3 then 'no_charge'
        when 4 then 'dispute'
        when 5 then 'unknown'
        when 6 then 'voided_trip'
        else 'other'
    end as payment_type_label,
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
    datediff('minute', pickup_datetime, dropoff_datetime) as trip_duration_minutes,
    round(
        trip_distance / nullif(datediff('minute', pickup_datetime, dropoff_datetime) / 60.0, 0),
        2
    ) as avg_speed_mph,
    case
        when fare_amount > 0 then round((tip_amount / fare_amount) * 100, 2)
        else null
    end as taux_pourboire,
    case
        when trip_distance <= 1 then 'court_trajet'
        when trip_distance <= 5 then 'trajet_moyen'
        when trip_distance <= 10 then 'long_trajet'
        else 'tres_long_trajet'
    end as distance_category,
    case
        when pickup_hour between 6 and 9 then 'rush_matinal'
        when pickup_hour between 10 and 15 then 'journee'
        when pickup_hour between 16 and 19 then 'rush_soir'
        when pickup_hour between 20 and 23 then 'soiree'
        else 'nuit'
    end as time_period,
    case
        when pickup_day_of_week_num in (0, 6) then 'weekend'
        else 'jour_semaine'
    end as day_type,
    source_file,
    loaded_at
from trips
