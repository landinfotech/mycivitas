# MyCivitas
MyCivitas is a GIS-integrated asset management application developed to address the unique needs of Canada’s small communities. CAM supports a three-phase approach to implementing asset management:

1. Asset Register: Capture asset locations and collect relevant data
2. Asset Prioritization: Prioritize assets based on risk
3. Capital and Operational Strategies: Identify capital projects and operational procedures to manage asset risk.

MyCivitas includes a web-interface for application users and a configured QGIS interface for application technicians. LandInfo Technologies and Kartoza are the official maintainers of MyCivitas.

[Check out a Civitas Asset Management wiki](https://github.com/landinfotech/mycivitas)

Here are a couple short videos to introduce some basic concepts:

[Technical Concepts](https://vimeo.com/showcase/8043243/video/516452692)

[Community Concepts](https://vimeo.com/showcase/8043243/video/516479586)

If you would like to become involved in this project, please send us message!


# QUICK INSTALLATION GUIDE

## Dependencies installation

The project provide **make** command that making setup process easier.
To install make on your machine or virtual box server, do:

```
sudo apt install make
```

Project has recipe that you can use to run the project in one command.
This recipe needs docker-compose to be able to use it.
To install it, do:

```
sudo apt install docker-compose
apt install ca-certificates curl gnup lsb-release  
```

## Docker installation

The project needs docker to be able to run it. To install it, please follow below instruction.

```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg     
```

On the next prompt line:

```
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg]https:download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Run apt update:

```
sudo apt-get update
```

This will install docker
```
sudo apt-get install  docker-ce-cli containerd.io
```

This will check if installation of docker was successful
```
sudo docker version
```
And it should return like this

```
Client: Docker Engine - Community
 Version:           20.10.9
 API version:       1.41
 Go version:        go1.16.8
 Git commit:        c2ea9bc
 Built:             Mon Oct  4 16:08:29 2021
 OS/Arch:           linux/amd64
 Context:           default
 Experimental:      true

```

### Manage docker as non-root

This will ensure that the docker can be executed without sudo.
```
sudo systemctl daemon-reload
sudo systemctl start docker
sudo usermod -a -G $USER
sudo systemctl enable docker
```

Verify that you can run docker commands without sudo.
```
docker run hello-world
```

For more information how to install docker, please visit [Install Docker Engine](https://docs.docker.com/engine/install/)

# Project Setup

## Clone mycivitas repository

This will clone the mycivitas repository to your machine
```
git clone https://github.com/landinfotech/mycivitas
```

## Set up the project

This will set up the mycivitas project on your machine
```
cd mycivitas
cd deployment
cp docker-compose.override.template.yml docker-compose.override.yml
cp sites-enabled/default.conf.template sites-enabled/default.conf
cp .template.env .env
make up
```
Wait until everything is done.

After everything is done, open up a web browser and go to [http://127.0.0.1/](http://127.0.0.1/) and the website will open.

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

# Email where alters should be sent. This will be used by let's encrypt and as the django admin email.
ADMIN_EMAIL=admin@example.com -> Default admin username
ADMIN_PASSWORD=admin -> Default admin password

# Email settings
EMAIL_HOST_USER=noreply@kartoza.com
EMAIL_HOST_PASSWORD=docker
EMAIL_HOST=smtp
EMAIL_HOST_DOMAIN=kartoza.com

HTTP_HOST=80
HTTPS_HOST=443


After you change the desired variable and do `make up`. It will rerun the project with new environment.