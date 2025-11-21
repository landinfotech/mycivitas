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

# Technician Views

## Views for Technicians

Technician views provide simplified, ready-to-use datasets that merge all essential asset information (base attributes, geometry, and key property values) into a single query result. These views remove the need for technicians to manually join multiple tables and are optimized for direct use in GIS tools, dashboards, and field workflows.

<br>

Technician views are designed to:

- Include only the attributes required for day-to-day technician workflows.
- Provide geometry and property values already joined and resolved.
- Hide internal or administrative fields that are irrelevant to end users.
- Enforce row-level security to restrict visibility to the technician’s community.

---

### Core Technician Views 

**`water_pipe`** is an example of a standard technician-oriented view. It merges all relevant pipe information from `feature_base`, `feature_geometry`, and `feature_property`. It is automatically filtered to the current user’s community using `user_community` and `CURRENT_USER`.

<br>

This view provides a streamlined set of columns, including:

- Core identifiers (`feature_id`)
- Geometry (point, line, or polygon)
- Pipe attributes (diameter, material, brand, model, contractor, length)
- Classification-related context such as class, sub-class, type, and system

<br>

Because the joins, filters, and property lookups are preconfigured, technicians can immediately map, query, update, and export water pipe information without reconstructing the model manually. All other technician views follow the same pattern for their respective asset classes.

---

## Database Processes

To ensure a smooth user experience, the database uses **automated triggers** that manage inserts, updates, and deletions behind the scenes. Technicians interact with assets using simple SQL operations, while the triggers handle the more complex logic such as property lifecycle management, geometry validation, class assignment, and community permissions.

Although the model includes many specialised triggers, they all follow the same principles. The triggers on `feature_base` form the foundation and illustrate the system’s behaviour clearly.

---

### Insert Triggers

**`feature_base_inserter()`** is the primary insertion trigger and serves as the most common entry point for standard assets: 

- Assigns `class_id`, `sub_class_id`, and `view_name` from arguments passed by the front end
- Automatically sets `user_name` using the current user’s community (`user_community`).
- Ensures new assets are created with correct classification, security, and view configuration
- Executes BEFORE INSERT on `feature_base`

---

### Update Triggers

**`feature_base_updater()`** manages all major updates to existing assets:

- Updates core attributes (`install date`, `description`, `condition`, `costs`, etc.).
- Preserves the user assignment by aligning `user_name` with `user_community`
- Ensures that assets remain compliant with classification and system rules
- Executes BEFORE UPDATE on `feature_base`

---

### Delete Triggers

`feature_deleter()` handles complete removal of an asset and ensures the database remains clean. This prevents orphaned rows and maintains database integrity:

- Deletes the row in `feature_base`
- Deletes linked geometry from `feature_geometry`
- Deletes all associated property records in `feature_property`

A `feature_deleter_nogeom` variant handles assets that do not contain geometry.

---

### Geometry Triggers

Geometry triggers ensure that all spatial data remains valid, standardised, and aligned with the correct SRID (EPSG:4326). Examples include `feature_geometry_point_inserter` and `feature_geometry_point_updater`, which manage point geometries.

<br>

For all geometry inserts and updates, these triggers:

- Replace invalid `NaN` WKT values
- Enforce the correct SRID
- Assign `user_name` based on the feature’s system and community

---

### Property Triggers 

Some asset classes use classification-specific property triggers. For example, water pipes use:

<br>

**pipe_property_inserter():**

- Automatically inserts pipe-specific properties (brand, material, diameter, contractor)
- Executed AFTER INSERT on `feature_base`

<br>

**pipe_property_updater():**

- Updates the corresponding property records using `OLD.feature_id`
- Executed AFTER UPDATE on feature_base

<br>

Many similar property triggers exist for other assets, each following the same pattern: automatic insert/update of the correct property set based on the feature’s classification.

---

## Row-Level Security

Row-level security (RLS) ensures technicians can only view and edit the assets they are allowed to access. It uses:

- `feature_base.user_name`
- `user_community` (maps database users to communities)
- `CURRENT_USER` (active database login)

<br>

Row-Level Security guarantees that:

- Technicians only interact with assets belonging to their assigned community
- All technician views automatically apply the security filter, no extra WHERE clauses required
- Admin and special roles may bypass these restrictions where appropriate

<br>

This enables a single shared database to securely support multiple municipalities or departments without data leakage between communities.

---

<br>
