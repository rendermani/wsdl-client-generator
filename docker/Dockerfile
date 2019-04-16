FROM php:7.2-fpm
RUN apt-get update && apt-get -y install  libxml2 libxml2-dev libxslt1.1 libxslt1-dev
RUN  docker-php-ext-install xsl

WORKDIR /code

RUN curl --silent --show-error https://getcomposer.org/installer | php
RUN mv  /code/composer.phar /usr/local/bin/composer

RUN yes | pecl install xdebug apcu \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=on" >> /usr/local/etc/php/conf.d/xdebug.ini\
    && echo "xdebug.remote_host=10.0.75.1" >> /usr/local/etc/php/conf.d/xdebug.ini\
    && echo "xdebug.remote_log=/var/log/xdebug" >> /usr/local/etc/php/conf.d/xdebug.ini
WORKDIR /code
#CMD ["php","src/xslt-wsdl-generator.php"]