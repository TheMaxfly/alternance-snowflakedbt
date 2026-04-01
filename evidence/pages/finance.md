---
title: Analyses Financieres
---

# Analyses financieres

Cette page couvre :

- revenus par jour de la semaine
- comparaison semaine / weekend
- analyse des pourboires selon le type de paiement
- rentabilite par zone

## Revenus par jour de la semaine

```sql revenus_jour_type
select *
from nyc_taxi.revenue_by_day_type
```

<BarChart
    data={revenus_jour_type}
    title="Revenu total par jour de la semaine"
    x=pickup_day_name
    y=total_revenue
    series=day_type
/>

<DataTable data={revenus_jour_type} title="Synthese revenus semaine et weekend"/>

## Pourboires selon le type de paiement

```sql pourboires_paiement
select *
from nyc_taxi.tip_by_payment_type
```

<BarChart
    data={pourboires_paiement}
    title="Taux de pourboire moyen par type de paiement"
    x=payment_type_label
    y=avg_taux_pourboire_pct
/>

<DataTable data={pourboires_paiement} title="Patterns de pourboires par mode de paiement"/>

## Zones les plus lucratives

```sql zones_lucratives
select *
from nyc_taxi.profitability_by_zone
```

<BarChart
    data={zones_lucratives}
    title="Top 15 zones par revenu total"
    x=pickup_location_id
    y=total_revenue
/>

<LineChart
    data={zones_lucratives}
    title="Revenu moyen par zone"
    x=pickup_location_id
    y=avg_revenue
/>

<DataTable data={zones_lucratives} title="Rentabilite par zone"/>
