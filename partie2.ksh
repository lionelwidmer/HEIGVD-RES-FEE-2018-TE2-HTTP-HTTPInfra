#!/bin/ksh

# Go to directory where we have our GIT repo
cd; cd H*

# Stop all running docker containers and delete them
docker rm -f `docker ps -qa`

# Switch GIT branch
git checkout fb-ajax-jquery

# Build image
cd docker-images/express-image
docker build -t res/express_datas .

# Run container
docker run -p 8080:3000 -d --name express_dynamic res/express_datas
