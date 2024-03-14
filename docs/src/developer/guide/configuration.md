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

# Project setup
<!-- This needs to be changed per project -->

## Clone MyCivitas repository

This will clone the MyCivitas repository to your machine
```
git clone https://github.com/landinfotech/mycivitas.git
```
<!-- Change this to project repository -->

## Set up the project

This will set up the MyCivitas project on your machine

```
cd mycivitas
cd deployment
cp docker-compose.override.template.yml docker-compose.override.yml
cp sites-enabled/default.conf.template sites-enabled/default.conf
cp .template.env .env
make up
```

Wait until everything is done.

After everything is done, open up a web browser and go to [http://127.0.0.1/](http://127.0.0.1/) and the dashboard will open:

By Default, we can use the admin credential:

```
username : admin@example.com
password : admin
```

## Set up different environment

To set up different environment, for example the Default credential, or the port of server, open **deployment/.env**.
You can check the description below for each of variable.

```
COMPOSE_PROJECT_NAME=amlit

DB_PORT=5432
INITIAL_FIXTURES=True -> Put true for django initial data.

# Django env
DATABASE_NAME=django -> Default django database name
DATABASE_USERNAME=docker -> Default django database username
DATABASE_PASSWORD=docker -> Default django database password
DATABASE_HOST=db -> Default django database host

DATABASE_CIVITAS_NAME=civitas -> Default civitas database name
DATABASE_CIVITAS_HOST=db -> Default civitas database host
DATABASE_CIVITAS_PORT=5432 -> Default civitas database port
DATABASE_CIVITAS_USERNAME=docker -> Default civitas database username
DATABASE_CIVITAS_PASSWORD=docker -> Default civitas database password

# Email where altersAfter you change the desired variable and do `make up`. It will rerun the project with new environment.
 should be sent. This will be used by let's encrypt and as the django admin email.
ADMIN_EMAIL=admin@example.com -> Default admin username
ADMIN_PASSWORD=admin -> Default admin password

# Email settings
EMAIL_HOST_USER=noreply@kartoza.com
EMAIL_HOST_PASSWORD=docker
EMAIL_HOST=smtp
EMAIL_HOST_DOMAIN=kartoza.com

HTTP_HOST=80
HTTPS_HOST=443
```

After you change the desired variable and do `make up`. It will rerun the project with the new environment.
