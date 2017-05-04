# check phpmyadmin example supervisor
# http://geekyplatypus.com/dockerise-your-php-application-with-nginx-and-php7-fpm/
# docker run --name php-nginx -p 8080:80 -v /home/alfred/workspace/docker/docker-php-nginx/code:/code -d kanalfred/php-nginx
FROM php:7.1-fpm

### [Nginx Copy Start] ###
MAINTAINER NGINX Docker Maintainers "docker-maint@nginx.com"

ENV NGINX_VERSION 1.11.13-1~jessie

RUN set -e; \
	NGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62; \
	found=''; \
	for server in \
		ha.pool.sks-keyservers.net \
		hkp://keyserver.ubuntu.com:80 \
		hkp://p80.pool.sks-keyservers.net:80 \
		pgp.mit.edu \
	; do \
		echo "Fetching GPG key $NGINX_GPGKEY from $server"; \
		apt-key adv --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPGKEY" && found=yes && break; \
	done; \
	test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1; \
	exit 0

RUN echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
						ca-certificates \
						nginx=${NGINX_VERSION} \
						nginx-module-xslt \
						nginx-module-geoip \
						nginx-module-image-filter \
						nginx-module-perl \
						nginx-module-njs \
						gettext-base \
	&& rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log
### [Nginx Copy End] ###

### Custom ###
COPY etc /etc/

# php lib & extensions
RUN apt-get update \
 && apt-get install -y \
        git zlib1g-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
 && docker-php-ext-install -j "$(nproc)" gd mbstring mysqli pdo pdo_mysql zip
 #&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
 #&& a2enmod rewrite \ 

 # replace php tcp to socket
 # /usr/local/etc/php-fpm.d/www.conf
 # fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
 # listen = /var/run/php-fpm/php-fpm.sock

 RUN apt-get update \
  && apt-get install -y supervisor 

EXPOSE 80 443 9000

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]