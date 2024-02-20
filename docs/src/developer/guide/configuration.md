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

## Clone [PROJECT_NAME] repository

This will clone the [PROJECT_NAME] repository to your machine
```
git clone https://github.com/project/repository.git
```
<!-- Change this to project repository -->

## Set up the project

This will set up the [PROJECT_NAME] project on your machine

```
cd [PROJECT_NAME]
cd deployment
cp docker-compose.override.template.yml docker-compose.override.yml
cp .template.env .env
cd ..
make up
```

Wait until everything is done.

After everything is done, open up a web browser and go to [http://127.0.0.1/](http://127.0.0.1/) and the dashboard will open:

By Default, we can use the admin credential:

```
username : admin
password : admin
```

## Set up different environment

To set up different environment, for example the Default credential, or the port of server, open **deployment/.env**.
You can check the description below for each of variable.

```
COMPOSE_PROJECT_NAME=[PROJECT_NAME]
NGINX_TAG=0.0.1  -> Change this for different nginx image
DJANGO_TAG=0.0.1 -> Change this for different django image
DJANGO_DEV_TAG=0.0.1 -> Change this for different django dev image

# Environments
DJANGO_SETTINGS_MODULE=core.settings.prod -> Change this to use different django config file
ADMIN_USERNAME=admin -> Default admin username 
ADMIN_PASSWORD=admin -> Default admin password
ADMIN_EMAIL=admin@example.com -> Default admin email
INITIAL_FIXTURES=True
HTTP_PORT=80 -> Change the port of nginx

# Database Environment
DATABASE_NAME=django -> Default database name
DATABASE_USERNAME=docker -> Default database username
DATABASE_PASSWORD=docker -> Default database password
DATABASE_HOST=db -> Default database host. Change this if you use cloud database or any new docker container.
RABBITMQ_HOST=rabbitmq

# Onedrive
PUID=1000
PGID=1000
```

After you change the desired variable and do `make up`. It will rerun the project with new environment.
