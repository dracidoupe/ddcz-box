FROM debian:squeeze
MAINTAINER Almad "bugs@almad.net"

RUN apt-get update && \
    apt-get -y -q install lighttpd php5-cgi php5-cli php5-curl php5-imagick php5-mysql daemontools daemontools-run procps

RUN groupadd w-dracidoupe-cz && \
    useradd w-dracidoupe-cz -g w-dracidoupe-cz && \
    mkdir /etc/service/dracidoupe.cz && \
    mkdir -p /var/www/dracidoupe.cz/www_root/www/php/

EXPOSE 80 443

WORKDIR /var/www/dracidoupe.cz/
