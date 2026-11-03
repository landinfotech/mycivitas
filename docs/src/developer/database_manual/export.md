---
title: MyCivitas
summary: MyCivitas is a cost-effective and user-friendly asset management platform designed specifically for small communities. This comprehensive solution offers an all-inclusive and easy-to-use platform, empowering users to efficiently record and manage their assets within a powerful information system. With MyCivitas, communities can streamline their asset management processes, ensuring a seamless and effective approach to organising and overseeing their valuable resources.
    - Lindie Strijdom
date: 01-10-2025
some_url: https://github.com/landinfotech/mycivitas
copyright: Copyright 2024, LandInfoTech
contact: support@civitas.ca
license: This program is free software; you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.
---

# Data Exports & Reporting

The reporting system is built around **materialized views** and **export datasets**, which together provide fast, consistent, and secure access to asset information. 

Raw asset tables are transformed into technician-friendly views, consolidated reporting tables, and finally community-filtered export layers used by dashboards, spreadsheets, and external systems.

---

## Materialized Views

Materialized views act as **pre-calculated reporting tables**. Instead of recalculating complex queries every time a report runs, the system stores the results in advance.

A scheduled **refresher script** updates these materialized views at set intervals (for example, nightly). This ensures that all summary reports, projections, and performance dashboards run quickly while still reflecting recent changes.

This avoids slow queries and provides a consistent data snapshot for analysis and reporting.

<br>

<div class="image-with-caption" style="text-align: center;">
  <img src="../img/export-1.png" alt="Materialized Views">
</div>

---

## Export Datasets

Export datasets provide asset information in a clean, reporting-ready format. They follow a structured pipeline that moves from raw asset tables to fully filtered, user-specific outputs. Water pipes are used here as an example of this export flow.

---

### Technician View (`water_pipe`)

The technician-facing starting point. This view joins `feature_base`, `feature_geometry`, and pipe-specific `feature_property` values into a single, clean dataset. It already includes user and community filtering, making it suitable for day-to-day mapping and field workflows.

<br>

**Source Tables:**

- `feature_base`
- `feature_geometry`
- `feature_property`
- `system`
- `user_community`

---

### Master Export (`mc_exporter`)

A unified export layer that merges **all asset types** into one comprehensive table. It flattens classifications, quantities, lifespan, risk scores, and property values into a single record per feature. All export slices, such as water pipes, roads, buildings, and amenities, are derived from this view.

<br>

**Source Tables:**

- Core asset tables (`feature_base`, `feature_geometry`, `feature_property`)
- Classification tables (`asset_class`, `asset_sub_class`, `asset_type`)
- Dimensional tables (`system`, `community`, `region`, `province`, `country`)
- Lifecycle and risk tables (`condition`, `pof`, `cof`, `deterioration`)
- Calculation tables (`feature_quantity`, `feature_calculation`, `feature_projection`)
- Many more (full flattening logic)

---

### Export Slice (`exp_water_pipe`)

A focused subset of the master export containing only water pipe assets. This layer has no security filtering and serves as the intermediate dataset before community-level access rules are applied.

<br>

**Source Tables:** 

- `mc_exporter`

---

### User-Secure Export (`mc_water_pipe`)

The final, community-filtered export for water pipes. It ensures users only access data for their own municipality, while administrators and technicians retain full visibility across all communities.

<br>

**Source Tables:**

- `exp_water_pipe`
- `user_community`

---

<br>

<div class="image-with-caption">
  <img src="../img/export-2.png" alt="Example View">
</div>

---

## Summary

| Dataset            | Purpose                           | Security | Source                   |
| ------------------ | --------------------------------- | -------- | ------------------------ |
| **water_pipe**     | Technician view of pipe assets    | Yes      | Base Tables              |
| **mc_exporter**    | Master export of all assets       | No       | All core + lookup tables |
| **exp_water_pipe** | Water pipe export slice           | No       | `mc_exporter`            |
| **mc_water_pipe**  | Secure, community-filtered export | Yes      | `exp_water_pipe`         |

<br>

This staged approach ensures:

- Consistent data structures across all assets
- Fast reporting and dashboards
- Role-based, community-based access control
- Predictable outputs for integrations and external exports

---

<br>
