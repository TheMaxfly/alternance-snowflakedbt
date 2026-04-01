---
title: Analyses de Volume
---

# Analyses de volume

Cette page couvre :

- top 10 des zones de depart
- evolution mensuelle du nombre de trajets
- distribution horaire de la demande

## Evolution mensuelle

```sql evolution_mensuelle
select *
from nyc_taxi.monthly_trip_evolution
```

<LineChart
    data={evolution_mensuelle}
    title="Evolution mensuelle du nombre de trajets"
    x=mois
    y=total_trips
/>

<LineChart
    data={evolution_mensuelle}
    title="Evolution mensuelle du revenu total"
    x=mois
    y=total_revenue
/>

## Top 10 des zones de depart

```sql top_zones_depart
select *
from nyc_taxi.top_departure_zones
```

<BarChart
    data={top_zones_depart}
    title="Top 10 des zones de depart"
    x=pickup_location_id
    y=total_trips
/>

<DataTable data={top_zones_depart} title="Detail des zones les plus actives"/>

## Distribution horaire

```sql distribution_horaire
select *
from nyc_taxi.hourly_distribution
```

<BarChart
    data={distribution_horaire}
    title="Distribution horaire de la demande"
    x=pickup_hour
    y=total_trips
/>

<LineChart
    data={distribution_horaire}
    title="Revenu moyen par heure"
    x=pickup_hour
    y=avg_revenue
/>
