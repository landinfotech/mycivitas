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

## Materialized Views

Materialized views are used for reporting and calculations. They store query results for performance reasons and are refreshed via a scheduled script.

## Export Datasets

- mc_exporter: master export combining all asset types.
- exp_water_pipe: export slice focusing only on water pipes.
- mc_water_pipe: security-filtered version of exp_water_pipe limited to the logged-in user’s community.

Pipeline model:

feature_base + feature_geometry + feature_property → water_pipe → mc_exporter → exp_water_pipe → mc_water_pipe.

## How It Fits Together

1. Insert: Triggers populate base fields (class_id, view_name, user_name).
2. Geometry: Geometry triggers enforce SRID and ownership.
3. Properties: Property triggers insert relevant default attributes.
4. Update: Triggers ensure consistency across base, geometry, and properties.
5. Delete: Cascade deletes remove related geometry and properties.
6. Views: Views (mv_features, aim_projection) present GIS-ready layers and planning metrics.
7. Capital Planning: Triggers assign features to community projects and calculate renewal costs.
8. Ownership: All triggers update user_name to maintain correct access control.
