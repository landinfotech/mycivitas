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

## Source Data Tables

- feature_base – core asset records.
- feature_geometry – stores geometries (point, line, polygon).
- feature_property + property – mini-EAV structure for specific asset attributes.

## Storage Logic

- Universal fields (id, class, system, ownership) live in feature_base.
- Geometries are linked by feature_id in feature_geometry.
- Flexible properties live in feature_property, allowing different asset types to store unique attributes.

## Mini-EAV

The mini-EAV (Entity–Attribute–Value) approach balances flexibility with structure. Instead of adding new columns for every possible attribute, properties are stored as rows. Example: a pipe’s diameter is stored in feature_property with a reference to a property definition table. A diagram should illustrate this.
