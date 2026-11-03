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

# Asset Data Concepts

## Asset Organization

Assets are organized hierarchically to reflect both their **real-world structure** and their administrative context. At the top of the geographic hierarchy is the **Country**, followed by **Province**, **Region**, and **Community**. These levels are primarily for reporting, planning, and filtering purposes.

Assets themselves live in the `feature_base` table and are always associated with a **System**, which groups related assets within a Community. This allows each asset to have a clear owner and location context.

---

### Hierarchy Overview

- **Country** → largest administrative unit

- **Province** → subdivisions of a country

- **Region** → subdivisions of a province

- **Community** → subdivisions of a region, where systems and assets are managed

- **System** → logical grouping of assets within a community

- **Asset (feature)** → individual item in `feature_base`, linked to one system

<br>

This organization enables:

- Clear accountability and ownership of assets

- Easy filtering, analysis, and reporting at any geographic level

- Logical grouping of related assets for maintenance, inspections, and capital planning

<br>

<div class="image-with-caption">
  <img src="../img/data-1.png" alt="Hierarchy">
</div>

---

## Asset Classification

Assets in the database are categorized using a **three-level hierarchy**, which defines what an asset is and how it should be managed. This structure ensures consistency, supports reporting, and integrates with processes like maintenance, inspections, risk management, and capital planning.

<br>

### Asset Class

The broadest grouping of assets. Stored in the `asset_class` table, each class has a name and description. Includes:

- Water Supply
- Wastewater Collection
- Stormwater Collection
- Transportation Network
- Electrical Network
- Natural Assets
- Structures
- Equipment
- Fleet
- Other

---

### Asset Sub-Class

A more specific grouping within a class, linked to units of measurement and deterioration models. Stored in `asset_sub_class` and linked to:

- `unit` - measurement unit for quantities
- `deterioration` - model describing asset condition decay

<br>

**Examples of sub-classes include:**

- Pipe
- Meter
- Monument
- Grassland
- Switchgear
- Pedestrian Walkway

<br>

**Units include:**

- Each arbitrary unit
- Metre
- Square metre
- Cubic metre

<br>

**Deterioration models include:**

- linear regression
- squared regression
- cubic regression

---

### Asset Type

Defines the actual asset item. Stored in `asset_type`. Each type has:

- Name and description
- Expected lifespan
- Unit maintenance cost
- Unit renewal cost

---

### Valid Combinations

These are stored in the `asset_classification_combination` table, which defines:

- `class_id` → links to `asset_class`
- `sub_class_id` → links to `asset_sub_class`
- `type_id` → links to `asset_type`
- `name` and `description`
- `def_stylename` → default styling for GIS or reports

<br>

**Examples of valid combination include:**

- Water Supply - Box - Meter
- Stormwater Collection - Motor - Gasoline
- Structures - Building - Substructure
- Natural Assets - Wetland - Swamp

<br>

This ensures only valid hierarchical combinations are used in `feature_base`, reducing errors and maintaining data integrity.

<br>

<div class="image-with-caption">
  <img src="../img/data-2.png" alt="Classification">
</div>

<br>

By combining classes, sub-classes, and types with units, deterioration models, and default styles, the database provides a structured yet flexible classification system suitable for planning, GIS visualization, and operational management.

---

## Attributes

Every feature in the database is defined by a combination of **base attributes** and **dynamic properties**. This dual structure allows the model to stay consistent while supporting flexibility for different asset types.

<br>

### Base Attributes

Base attributes are stored in the `feature_base` table. These include identifiers, classification references, cost information, ownership, and other universal fields that apply to all features.

Each record in `feature_base` links to a specific system (`system_id`) and defines its type using `class_id`, `sub_class_id`, and `type_id`. This table acts as the backbone of all asset data in the system.

<br>

Other typical fields include:

- quantity
- description
- condition_id
- lifespan
- install_date
- inspection_date
- renewal_cost / maintenance_cost
- pof / cof (Probability & Consequence of Failure)
- user_name (for access control)

---

### Flexible Properties

Some assets have unique attributes that don’t apply to all types — for example, *diameter* for a pipe or *surface type* for a road. To handle this without constantly changing the database schema, the system uses a simplified **Entity–Attribute–Value (EAV)** model.

Each feature can have one or more custom properties stored in the `feature_property` table, which links to definitions in the `property` lookup table. This makes it easy to add or modify attributes dynamically while keeping the database structure stable.

---

<br>
