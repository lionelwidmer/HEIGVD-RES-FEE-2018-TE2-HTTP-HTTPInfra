#!/bin/ksh

# Go to directory where we have our GIT repo
cd; cd H*

# Stop all running docker containers and delete them
docker rm -f `docker ps -qa`

# Switch GIT branch
git checkout fb-ajax-jquery

# Build image
cd docker-images/apache-static-image
docker build -t res/apache_php .

# Run container
docker run -d --name apache_static res/apache_php
docker run -d --name express_dynamic res/express_datas
docker run -d --name apache_rp -p 8080:80 res/apache_rp_static
