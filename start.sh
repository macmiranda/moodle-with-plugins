#!/bin/sh
exec php-fpm7 &
exec nginx
