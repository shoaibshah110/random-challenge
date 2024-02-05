# Use the official Alpine Linux image with PHP
FROM php:8.2-alpine

# Set working directory
WORKDIR /var/www/html

# Install dependencies
RUN apk add --no-cache \
    curl \
    libpng \
    libjpeg-turbo \
    libwebp \
    freetype \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    freetype-dev \
    libzip-dev \
    composer \
    php-openssl \
    openssl \
    zip \
    unzip

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy application files
COPY . .

# Expose port
EXPOSE 8000

# Start Laravel server
CMD php artisan serve --port=8000 --host=0.0.0.0
