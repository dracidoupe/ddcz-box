#! /bin/bash
mkdir -p /etc/service/dracidoupe.cz && \
mkdir -p /etc/lighttpd/modules && \
mkdir -p /etc/lighttpd/sites && \
localedef -i en_US -c -f UTF-8 en_US && \
echo "deb http://archive.debian.org/debian squeeze main" > /etc/apt/sources.list && \
echo "deb http://archive.debian.org/debian squeeze-lts main" >> /etc/apt/sources.list && \
echo "Acquire::Check-Valid-Until false;" > /etc/apt/apt.conf && \
apt-get update && \
apt-get -y --force-yes -q install lighttpd php5-cgi php5-cli php5-curl php5-imagick php5-mysql daemontools daemontools-run procps spawn-fcgi && \
lighttpd-enable-mod rewrite redirect evhost fastcgi-php accesslog compress && \
groupadd w-dracidoupe-cz && \
useradd w-dracidoupe-cz -g w-dracidoupe-cz && \
groupadd wwwserver && \
useradd lighttpd -g www-data -g wwwserver && \

mount -t ext4 /dev/xvdf1 /var/www && \
mkdir /var/www/null ;
mkdir -p /var/www/fastcgi/sockets/w-dracidoupe-cz/ ;
mkdir -p chown www-data:www-data /var/www/dracidoupe.cz/logs/ ; chown -R www-data:-data /var/www/dracidoupe.cz/logs/
mkdir -p /var/www/dracidoupe.cz/www_root/www/php/;
chown -R w-dracidoupe-cz:www-data /var/www/fastcgi/sockets/w-dracidoupe-cz/ ;
chown -R w-dracidoupe-cz:www-data /var/www/dracidoupe.cz/

