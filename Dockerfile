# Multi-stage build for Symfony app
# Stage 1: composer install
FROM composer:2.7 AS builder
WORKDIR /app
# Copy composer files and full project
COPY . /app
# Install missing dependencies first, then install all
RUN composer require --no-update "scheb/2fa-bundle:^6.0" "scheb/2fa-totp:^6.0" "endroid/qr-code:^4.0" && \
    composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader --no-scripts --ignore-platform-reqs --no-ansi || \
    composer update --no-dev --prefer-dist --no-interaction --optimize-autoloader --no-scripts --ignore-platform-reqs --no-ansi
RUN composer dump-autoload --optimize --no-interaction

# Stage 2: runtime image
FROM php:8.2-apache
# Install system dependencies, PHP extensions, and enable Apache rewrite
RUN apt-get update && apt-get install -y \
    libzip-dev \
    zip \
    unzip \
    git \
    libicu-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libsqlite3-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql pdo_sqlite intl gd \
    && docker-php-ext-enable gd \
    && a2enmod rewrite

WORKDIR /var/www/html
COPY --from=builder /app /var/www/html
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

# Manually copy EasyAdmin assets to public directory (assets:install needs DB which isn't available during build)
RUN mkdir -p /var/www/html/public/bundles/easyadmin && \
    cp -r /var/www/html/vendor/easycorp/easyadmin-bundle/src/Resources/public/* /var/www/html/public/bundles/easyadmin/ && \
    chown -R www-data:www-data /var/www/html/public/bundles

# Serve Symfony from the `public` directory
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf \
 && printf '\n<Directory /var/www/html/public>\n    AllowOverride All\n</Directory>\n' >> /etc/apache2/apache2.conf

EXPOSE 80
CMD ["apache2-foreground"]
