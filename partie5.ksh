#!/bin/ksh

# Go to directory where we have our GIT repo
cd; cd H*

# Stop all running docker containers and delete them
docker rm -f `docker ps -qa`

# Switch GIT branch
git checkout fb-dynamic-configuration

# Build image
cd docker-images/apache-reverse-proxy
docker build -t res/apache_rp .

# Run various container
docker run -d res/apache_php
docker run -d res/apache_php
docker run -d res/apache_php
docker run -d res/express_datas
docker run -d res/express_datas
docker run -d res/express_datas
docker run -d --name apache_static res/apache_php
docker run -d --name express_dynamic res/express_datas

# Run containers
ip_static=`docker inspect apache_static | grep IPAddress | grep -v Secondary | head -1 | cut -d":" -f2 | cut -d"\"" -f2`
ip_dynamic=`docker inspect express_dynamic | grep IPAddress | grep -v Secondary | head -1 | cut -d":" -f2 | cut -d"\"" -f2`
docker run -d --name apache_rp -p 8080:80 -e STATIC_APP=${ip_static}:80 -e DYNAMIC_APP=${ip_dynamic}:3000 res/apache_rp
