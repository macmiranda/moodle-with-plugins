FROM alpine:3.12

LABEL Name=docker.io/maurelio/moodle-with-plugins Version=0.0.1 maintainer=marco.aurelio@gigacandanga.net.br

EXPOSE 80
ARG VERSION=3.10.0
ARG MOOSH_VERSION=0.32
ARG COMPOSER_VERSION=1.10.6
ARG UPLOADSIZE=300M

ENV TZ America/Sao_Paulo
ENV LANG pt_BR.UTF-8
ENV LANGUAGE pt_BR.UTF-8
ENV LC_ALL pt_BR.UTF-8

RUN apk update && apk add curl
RUN	echo "Downloading moodle"; \
	curl -o moodle.tar.gz -fSL "https://github.com/moodle/moodle/archive/v${VERSION}.tar.gz"; \
	mkdir -p /var/www/moodle; \
	tar -xf moodle.tar.gz -C/var/www/moodle --strip 1; \
	rm moodle.tar.gz
RUN apk add --no-cache openssl php7-openssl php7-pecl-redis php7-pecl-mcrypt \
    php7-bcmath php7-pspell php7-gd php7-intl php7-pgsql php7-xml php7-curl \
    php7-xsl php7-xmlrpc php7-json php7-opcache php7-pecl-uploadprogress \
    php7-ldap php7-zip php7-soap php7-mbstring php7-fpm php7-pecl-apcu php7-phar\
    php7-pecl-imagick php7-mbstring php7-gettext php7-iconv php7-bz2 php7-cli\
    php7-simplexml php7-tokenizer php7-xmlwriter nginx
RUN apk add tzdata && \
    cp /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    apk del tzdata
RUN echo "America/Sao_Paulo" >  /etc/timezone

# set recommended opcache settings 
# see https://www.php.net/manual/en/opcache.installation.php
## see https://docs.moodle.org/38/en/OPcache
RUN { \
	echo 'opcache.memory_consumption=1024'; \
	echo 'opcache.interned_strings_buffer=8'; \
	echo 'opcache.max_accelerated_files=10000'; \
	echo 'opcache.revalidate_freq=60'; \
	echo 'opcache.fast_shutdown=1'; \
	echo 'opcache.enable_cli=1'; \
	echo 'opcache.use_cwd=1'; \
	echo 'opcache.validate_timestamps = 1'; \
	echo 'opcache.save_comments=1'; \
	echo 'opcache.enable_file_override=0'; \
	} > /etc/php7/conf.d/opcache.ini

# usefull for moodle

RUN { \
	echo 'file_uploads = On'; \
	echo 'memory_limit = 512M'; \
	echo 'upload_max_filesize = '${UPLOADSIZE}; \
	echo 'post_max_size = '${UPLOADSIZE}; \
	echo 'max_execution_time = 600'; \
	} > /etc/php7/conf.d/uploads.ini

RUN	echo "Installing composer"; \
	curl -o composer.phar -fSL "https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar"; \
	chmod +x ./composer.phar; \
	mv ./composer.phar /usr/local/bin/composer

RUN	echo "Installing moosh"; \
	curl -o moosh.tar.gz -fSL "https://github.com/tmuras/moosh/archive/${MOOSH_VERSION}.tar.gz"; \
	mkdir /usr/local/lib/moosh; \
    tar -xf moosh.tar.gz -C/usr/local/lib/moosh --strip 1; \
	apk add --no-cache git && composer install -d /usr/local/lib/moosh \
    && apk del git; \
	ln -s /usr/local/lib/moosh/moosh.php /usr/local/bin/moosh; \
	rm moosh.tar.gz

# Fix the original permissions of /tmp, the PHP default upload tmp dir.

RUN chmod 777 /tmp && chmod +t /tmp ;\
	chown -R www-data:www-data /var/www;\
    mkdir /run/nginx;\
    sed  -i '/error_log/s/^.*$/daemon off;\nerror_log \/dev\/stdout warn;/' /etc/nginx/nginx.conf;\
    sed  -i '/access_log/s/^.*$/\taccess_log \/dev\/stdout main;/' /etc/nginx/nginx.conf;\
    sed  -i '/client_max_body_size/s/^.*$/\tclient_max_body_size '${UPLOADSIZE}';/' /etc/nginx/nginx.conf

COPY default.conf /etc/nginx/conf.d/

CMD ["nginx"]
