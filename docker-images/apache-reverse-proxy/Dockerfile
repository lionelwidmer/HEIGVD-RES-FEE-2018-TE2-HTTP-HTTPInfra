FROM php:7.2-apache

COPY conf/ /etc/apache2/

RUN a2enmod proxy
RUN a2enmod proxy_http
RUN a2ensite 00*
RUN apt-get update && apt-get install -y vim
