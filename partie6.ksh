#!/bin/ksh

# Go to directory where we have our GIT repo
cd; cd H*

# Stop all running docker containers and delete them
docker rm -f `docker ps -qa`

# Switch GIT branch
git checkout fb-static-load-balancing

# Build image
cd docker-images/apache-load-balancing
docker build -t res/apache_lb  .
cd ../express-image
docker build -t res/express_datas  .

# Run various container
docker run -d res/express_datas
docker run -d res/express_datas
docker run -d res/express_datas
docker run -d res/apache_php
docker run -d res/apache_php
docker run -d res/apache_php

# Run containers
docker run -d --name apache_lb -p 8080:80 res/apache_lb
