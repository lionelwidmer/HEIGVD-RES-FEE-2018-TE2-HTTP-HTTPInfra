FROM php:7.2-apache

#RUN apt-get update && apt-get install -y vim

COPY conf/ /etc/apache2

RUN a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests
RUN a2ensite 000-* 001-*
