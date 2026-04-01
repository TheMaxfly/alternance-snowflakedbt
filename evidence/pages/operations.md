---
title: Analyses Operationnelles
---

# Analyses operationnelles

Cette page couvre :

- vitesse moyenne par periode
- distance moyenne des trajets
- duree moyenne par zone comme proxy de temps d'attente

## Vitesse moyenne par periode

```sql vitesse_par_periode
select *
from nyc_taxi.speed_by_period
```

<BarChart
    data={vitesse_par_periode}
    title="Vitesse moyenne par periode temporelle"
    x=time_period
    y=avg_speed_mph
/>

<DataTable data={vitesse_par_periode} title="Fluidite du trafic par periode"/>

## Distance moyenne des trajets

```sql distance_moyenne_patterns
select *
from nyc_taxi.average_distance_patterns
```

<BarChart
    data={distance_moyenne_patterns}
    title="Distance moyenne par periode et type de jour"
    x=time_period
    y=avg_distance
    series=day_type
/>

<DataTable data={distance_moyenne_patterns} title="Patterns de mobilite"/>

## Duree moyenne par zone

```sql duree_moyenne_zone
select *
from nyc_taxi.average_duration_by_zone
```

<BarChart
    data={duree_moyenne_zone}
    title="Top 15 zones par duree moyenne de trajet"
    x=pickup_location_id
    y=avg_duration_min
/>

<LineChart
    data={duree_moyenne_zone}
    title="Vitesse moyenne associee par zone"
    x=pickup_location_id
    y=avg_speed_mph
/>

<DataTable
    data={duree_moyenne_zone}
    title="Duree moyenne par zone de depart"
/>
