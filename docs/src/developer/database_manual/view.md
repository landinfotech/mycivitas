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

Technician-friendly views provide simplified access to asset data without requiring staff to manually join multiple tables. For example, the water_pipe view combines base records, geometry, and properties into a single query result. This allows technicians to query and visualize assets in GIS tools or reports without handling complex joins.

Views:

- Present only the attributes relevant to a technician’s workflow.
- Ensure geometry and related properties are already joined.
- Filter out unnecessary fields.
- Enforce community-level access control.

## Database Processes

Underlying tables are maintained using triggers that automatically handle inserts, updates, and deletes:

- Insert triggers: Populate default values, assign user ownership, clean geometries, and insert required properties.
- Update triggers: Ensure consistency across related tables (e.g. updating a pipe’s material updates the corresponding property record).
- Delete triggers: Cascade deletions from feature_base into feature_geometry and feature_property to prevent orphaned records.

These triggers allow technicians to interact with the database through standard insert/update/delete commands without needing to manage linked tables manually.

## Row-Level Security

Access control is enforced via the user_name field in feature_base and its relationship with the user_community table. This ensures that:

- Users can only see or edit features linked to their community.
- Queries run against views are automatically filtered to the current user’s community using CURRENT_USER.
- Special roles (e.g. admin, technician) bypass these restrictions when needed.

This mechanism allows the same database to serve multiple communities securely.
