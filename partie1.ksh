#!/bin/ksh

# Go to directory where we have our GIT repo
cd; cd H*

# Stop all running docker containers and delete them
docker rm -f `docker ps -qa`

# Switch GIT branch
git checkout fb-apache-static

# Build image
cd docker-images/apache-static-image
docker build -t res/apache_php .

# Run container
docker run -p 8080:80 -d --name apache_static res/apache_php
