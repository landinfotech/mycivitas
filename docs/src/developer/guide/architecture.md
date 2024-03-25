---
title: MyCivitas
summary: MyCivitas is a cost-effective and user-friendly asset management platform designed specifically for small communities. This comprehensive solution offers an all-inclusive and easy-to-use platform, empowering users to efficiently record and manage their assets within a powerful information system. With MyCivitas, communities can streamline their asset management processes, ensuring a seamless and effective approach to organising and overseeing their valuable resources.
    - Jeremy Prior
    - Ketan Bamniya
date: 01-02-2024
some_url: https://github.com/landinfotech/mycivitas
copyright: Copyright 2024, LandInfoTech
contact: support@civitas.ca
license: This program is free software; you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.
---

# System architecture

In this section, we outline the system architecture using ER Diagrams, Software Component Diagrams etc. and key libraries / frameworks used in this project.

## Software components used
<!-- These are generic. Customise as needed per project -->

The following is a list, with brief descriptions, of the key components used in creating this platform. Please refer to their individual documentation for in-depth technical information.

| Logo | Name | Notes |
|------------|---------|----------------|
|![](https://static.djangoproject.com/img/logos/django-logo-negative.svg){: style="height:30px;width:30px"} | [Django](https://djangoproject.com) | Django makes it easier to build better web apps more quickly and with less code. | 
|![](img/architecture-backbone-js-icon.svg){: style="height:30px;width:30px"}| [Backbone JS](https://backbonejs.org/) | Backbone.js gives structure to web applications by providing models with key-value binding and custom events, collections with a rich API of enumerable functions, views with declarative event handling, and connects it all to your existing API over a RESTful JSON interface.|
| ![](img/architecture-docker.svg){: style="height:30px;width:30px"} | [Docker](https://docker.com) | Accelerate how you build, share, and run applications. Docker helps developers build, share, and run applications anywhere — without tedious environment configuration or management. |
| ![](img/architecture-celery.svg){: style="height:30px;width:30px"} | [Celery](https://docs.celeryq.dev) | Celery is a simple, flexible, and reliable distributed system to process vast amounts of messages, while providing operations with the tools required to maintain such a system. It’s a task queue with focus on real-time processing, while also supporting task scheduling. |
| ![](img/architecture-celery.svg){: style="height:30px;width:30px"} | [Celery Beat](https://github.com/celery/django-celery-beat) | This extension enables you to store the periodic task schedule in your database. The periodic tasks can be managed from the Django Admin interface, where you can create, edit and delete periodic tasks and how often they should run. |
| ![](img/architecture-drf.png){: style="height:30px;width:30px"} | [Django Rest Framework](https://www.django-rest-framework.org/) | Django REST framework is a powerful and flexible toolkit for building Web APIs. |
| ![](img/architecture-maplibre-logo.svg){: style="height:30px;width:30px"} | [MapLibre](https://maplibre.org/)  | Open-source mapping libraries for web and mobile app developers. |
| ![](img/architecture-postgis.svg){: style="height:30px;width:30px"} | [PostGIS](https://postgis.net/) | PostGIS extends the capabilities of the PostgreSQL relational database by adding support storing, indexing and querying geographic data. |
| ![](img/architecture-postgresql.png){: style="height:30px;width:30px"} | [PostgreSQL](https://www.postgresql.org/) | PostgreSQL is a powerful, open source object-relational database system with over 35 years of active development that has earned it a strong reputation for reliability, feature robustness, and performance.  |

<!-- ## Docker components

The following diagram represents the docker containers, ports and volumes that are used to compose this platform.

![Architecture Docker Diagram]()

## ER diagram

The following diagram represents all of the database entities that are created by the Django ORM (Object Relational Mapper). Right click the image and open it in its own tab to see it at full resolution.

![Architecture ERD]()

🪧 If you already have all of the above criteria met, you can move on to [Prerequisites](prerequisites.md) to start the process of getting your local development environment set up. -->
