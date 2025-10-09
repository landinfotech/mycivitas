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

# Data Model Overview

This section outlines how asset data is physically stored and linked within the database. It focuses on the core tables, their relationships, and the logic that keeps the model both flexible and consistent.

---

## Source Data Tables

The asset database is built on a set of core source tables that store essential information about every feature, its geometry, and its extended attributes. Together, these tables form the foundation of the data model.

---

### feature_base

The `feature_base` table is the **central repository** for all assets in the system. Each record represents a single feature and contains its core identifiers, classifications, ownership, and cost information.

<br>

It stores key references such as:

- `system_id` – links each feature to its parent system
- `class_id`, `sub_class_id`, `type_id` – define what the feature is
- `pof`, `cof`, and `condition_id` – track condition and performance
- `renewal_cost` and `maintenance_cost` – support lifecycle and capital planning

<br>

This table forms the structural backbone of the database, ensuring every asset is consistently defined and traceable to its community and system.

---

### feature_geometry

The `feature_geometry` table stores the **spatial component** of each asset. It maintains geometry data in one or more formats — points, lines, or polygons — depending on the type of asset.

Each geometry record is linked to its corresponding feature in `feature_base` using `feature_id`. This separation of geometry from attributes improves flexibility, allows spatial indexing, and supports efficient updates without modifying the main feature table.

---

### feature_property

Additional, asset-specific details are managed through a **flexible property system**. The `feature_property` table links features to individual property values, while `property` defines the list of valid property names.  

This structure supports unlimited attribute extension — such as storing a pipe’s *material* or *diameter* — without altering the schema. The detailed design and logic of this system are explained further in the **Mini-EAV** section below.

<br>

<div class="image-with-caption">
  <img src="../img/model-1.png" alt="Source Tables">
</div>

---

## Storage Logic

### Hierarchical Structure

The system follows a **hierarchical relational structure** beginning at the **Country** level and moving downward through **Province → Region → Community → System**. Each level references the ID of its parent, maintaining a clear spatial and administrative chain of dependency.

---

### Feature Integration

All asset records (such as roads, bridges, or pipelines) are centralized in the `feature_base` table. Features do **not** link directly to administrative layers; instead, they connect through their associated **System**, which belongs to a Community.

This unified model supports cross-cutting analysis across asset types and maintains consistency in how features are managed and queried.

---

### Project Management

To track capital works and organizational responsibilities, the system includes three key supporting tables:

- `department` – Stores department names and links them to their respective communities.

- `capital_project` – Stores project details such as name, year, estimated cost, associated community, department, geometry, and description.

- `capital_project_feature_combination` – Acts as a relationship table linking individual assets in `feature_base` to their respective capital projects.

<br>

Each of these maintains proper foreign key references to ensure data integrity:

- Departments link back to **community**.
- Capital projects link to both **community** and **department**.
- The feature–project combination links **feature_base** entries to their related **capital_project**.

<br>

<div class="image-with-caption">
  <img src="../img/model-2.png" alt="Storage">
</div>

---

## Mini-EAV

The database uses a **Mini–Entity–Attribute–Value (EAV)** structure to manage flexible asset attributes without modifying the schema for every new type of data.

This design provides balance between **structure** and **extensibility**, allowing both standard and asset-specific fields to coexist cleanly.

---

### How It Works

The `feature_property` table acts as a *link table* between `feature_base` (the asset record) and `property` (the property definitions).Each record in `feature_property` defines a single attribute for a feature, storing:

- `feature_id` → the asset being described
- `property_id` → what the attribute represents (e.g., “material”)
- `value_text` → the attribute’s value (e.g., “PVC”)

<br>

The `property` table lists all property definitions, ensuring that attribute names remain consistent and reusable.

<br>

<div class="image-with-caption">
  <img src="../img/model-3.png" alt="EAV">
</div>

---

### Benefits

This approach provides flexibility and consistency without compromising efficiency. New properties can be introduced by simply adding a record to the `property` table, rather than altering the database schema. 

Common fields remain in `feature_base`, while asset-specific attributes are stored only where needed in `feature_property`. This separation ensures data integrity, reduces redundancy, and keeps the schema lean while supporting scalable asset growth.

---

### Example

Instead of adding a `material` column to every asset table, only pipes that require it will have:

<br>

<div class="image-with-caption">
  <img src="../img/model-4.png" alt="Example Attributes">
</div>

<br>

In this example, **Feature 173** has a property **material = PVC**.

The Mini-EAV model therefore keeps the schema lean, structured, and adaptable to new asset data as the system grows.

---

<br>
