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

# Project Prerequisites

## Installation of Docker

Ensure that Docker is installed on the machine where the environment will be set up using Docker Compose.
Follow the official Docker installation guide for your operating system to install Docker: [Docker Installation Guide](https://docs.docker.com/engine/install/).

## Minimal Dependencies Outside Docker

Since the environment is set up using Docker Compose, there are minimal dependencies outside Docker itself.
Docker Compose will handle the setup and orchestration of containers, so there's no need for additional software or dependencies.

## Configuration in Docker Compose

Define the services and configurations needed for the environment in the docker-compose.yml file.
Specify any required Docker images, volumes, networks, ports, environment variables, and other settings in the Docker Compose configuration.

## Sudo Rights for Docker

Ensure that the user running Docker commands has sudo rights to execute Docker commands without requiring a password.
Granting sudo rights to Docker commands can be done by adding the user to the Docker group. However, it's essential to understand the security implications of this action.

## Testing Docker Setup:

After installing Docker and configuring Docker Compose, test the setup by running docker-compose up command from the directory containing the docker-compose.yml file.
Verify that the containers start up successfully, and the environment functions as expected.

By following these points, you can ensure that Docker is installed, Docker Compose is configured, and the environment is set up smoothly within Docker containers.