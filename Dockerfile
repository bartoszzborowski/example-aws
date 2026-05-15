FROM php:8.3-fpm-alpine AS base

RUN apk add --no-cache \
    nginx supervisor curl \
    libpng-dev libjpeg-turbo-dev freetype-dev \
    icu-dev oniguruma-dev libzip-dev

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) pdo_mysql bcmath opcache gd intl mbstring zip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# --- build stage ---
FROM base AS build
WORKDIR /var/www/app

COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction

COPY . .
RUN composer dump-autoload --optimize \
    && php artisan route:cache \
    && php artisan view:cache

# --- production image ---
FROM base
WORKDIR /var/www/app

COPY --from=build /var/www/app /var/www/app
COPY docker/nginx.conf       /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/php-fpm.conf     /usr/local/etc/php-fpm.d/www.conf
COPY docker/entrypoint.sh    /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && mkdir -p storage/framework/{cache,sessions,views} storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
