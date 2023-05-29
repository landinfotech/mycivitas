#--------- Generic stuff all our Dockerfiles should start with so we get caching ------------
# Note this base image is based on debian
FROM ubuntu:18.04
MAINTAINER Irwan Fathurrahman<meomancer@gmail.com>

# Pandoc needed to generate rst dumps, uic compressor needed for django-pipeline
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y
RUN apt-get install -y python3-pip python3-dev gdal-bin gettext libcurl4-openssl-dev libssl-dev yui-compressor git vim

ENV PATH /usr/local/bin:$PATH

ADD deployment/docker/uwsgi.conf /uwsgi.conf

#RUN dpkg-divert --local --rename --add /sbin/initctl

RUN apt-get install locales -y && \
    echo "en_ZA.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen en_ZA.UTF-8
ENV LANG en_ZA.UTF-8
ENV LANGUAGE en_ZA:en
ENV LC_ALL en_ZA.UTF-8

ADD deployment/docker/REQUIREMENTS.txt /REQUIREMENTS.txt
RUN pip3 install --upgrade pip && pip install --upgrade pip
RUN pip install -r /REQUIREMENTS.txt
RUN pip install uwsgi==2.0.18

RUN ln -s /usr/bin/python3 /usr/local/bin/python

ADD django_project /home/web/django_project
ADD deployment/docker/entrypoint.sh /entrypoint.sh
ADD deployment/docker/initialize.py /initialize.py

# Open port 8080 as we will be running our uwsgi socket on that
EXPOSE 8080

WORKDIR /home/web/django_project
ENTRYPOINT ["/home/web/django_project/entrypoint.sh"]
CMD ["uwsgi", "--ini", "/uwsgi.conf"]
