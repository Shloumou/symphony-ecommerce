# Multi-stage build for Symfony app
# Stage 1: composer install
FROM composer:2 AS builder
WORKDIR /app
# Copy full project before running composer so post-install scripts (cache:clear, etc.) can access project files like bin/console
COPY . /app
# Update composer.lock to include new packages
RUN composer update --no-dev --prefer-dist --no-interaction --optimize-autoloader --no-scripts
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
    libpq-dev \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_pgsql intl gd zip opcache \
    && docker-php-ext-enable gd opcache \
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
