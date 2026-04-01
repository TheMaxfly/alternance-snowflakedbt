---
title: Tableau de Bord NYC Taxi
---

# Tableau de bord analytique

Cette application Evidence presente les analyses demandees dans la partie avancee du projet :

- [Analyses de volume](volume)
- [Analyses financieres](finance)
- [Analyses operationnelles](operations)

```sql indicateurs_cles
select
    sum(total_trips) as total_trips,
    round(sum(total_revenue), 2) as total_revenue,
    round(avg(avg_revenue_per_trip), 2) as avg_revenue_per_trip,
    round(avg(avg_taux_pourboire_pct), 2) as avg_taux_pourboire_pct
from nyc_taxi.daily_summary
```

<Value data={indicateurs_cles} column=total_trips title="Nombre total de trajets"/>
<Value data={indicateurs_cles} column=total_revenue title="Revenu total"/>
<Value data={indicateurs_cles} column=avg_revenue_per_trip title="Revenu moyen par trajet"/>
<Value data={indicateurs_cles} column=avg_taux_pourboire_pct title="Taux de pourboire moyen (%)"/>

## Apercu rapide

```sql top_pages
select 'Volume' as section, 'Zones, evolution mensuelle, distribution horaire' as contenu
union all
select 'Finance', 'Revenus semaine/weekend, pourboires par paiement, rentabilite par zone'
union all
select 'Operations', 'Vitesse par periode, distance moyenne, duree moyenne par zone'
```

<DataTable data={top_pages} title="Structure du dashboard"/>

Consulte ensuite :

- [Page volume](volume)
- [Page finance](finance)
- [Page operations](operations)
