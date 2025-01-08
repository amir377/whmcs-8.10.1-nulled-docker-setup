# Use the specified PHP version dynamically or default to 8.1
FROM php:8.1-apache

# Set the timezone
ENV TZ=${TZ}

# Set working directory
WORKDIR /var/www

# Install system dependencies, PHP extensions, and nano
RUN apt-get update && apt-get install -y \
    cron \
    bash \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libfreetype6-dev \
    libzip-dev \
    git \
    curl \
    unzip \
    libxml2-dev \
    certbot \
    python3-certbot-apache \
    nano \
    libonig-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        pdo_mysql \
        zip \
        bcmath \
        pcntl \
        soap \
        mbstring \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PECL extensions (Swoole)
RUN pecl install swoole \
    && docker-php-ext-enable swoole

# Apply the timezone configuration to PHP
RUN echo "date.timezone = ${TZ}" >> /usr/local/etc/php/conf.d/timezone.ini

# Enable mod_rewrite for Apache
RUN a2enmod rewrite

# Copy application files into the container
COPY . /var/www/html/

# Copy the custom Apache configuration file
COPY docker/apache/000-default.conf /etc/apache2/sites-available/000-default.conf

# Ensure proper ownership and permissions
RUN chown -R www-data:www-data /var/www/html

# Set directory permissions
#RUN find /var/www/html -type d -exec chmod 755 {} \;  # Directories: rwxr-xr-x
#RUN find /var/www/html -type f -exec chmod 644 {} \;  # Files: rw-r--r--

# Create a writable directory for automatic updates
RUN mkdir -p /var/www/whmcs-update \
    && chmod 777 /var/www/whmcs-update

# Install envsubst (part of gettext)
RUN apt-get update && apt-get install -y gettext

# Copy the configuration template and PHP generation script
COPY docker/config/generate_config.php /usr/local/bin/generate_config.php
COPY docker/config/configuration.php.template /var/www/html/docker/config/configuration.php.template

# Make the script executable
RUN chmod +x /usr/local/bin/generate_config.php

ENV LICENCE=${LICENCE}
ENV DB_HOST=${DB_HOST}
ENV DB_PORT=${DB_PORT}
ENV DB_USERNAME=${DB_USERNAME}
ENV DB_PASSWORD=${DB_PASSWORD}
ENV DB_NAME=${DB_NAME}
ENV DB_TLS_CA=${DB_TLS_CA}
ENV DB_TLS_CA_PATH=${DB_TLS_CA_PATH}
ENV DB_TLS_CERT=${DB_TLS_CERT}
ENV DB_TLS_CIPHER=${DB_TLS_CIPHER}
ENV DB_TLS_KEY=${DB_TLS_KEY}
ENV DB_TLS_VERIFY_CERT=${DB_TLS_VERIFY_CERT}
ENV MYSQL_CHARSET=${MYSQL_CHARSET}
ENV CC_ENCRYPTION_HASH=${CC_ENCRYPTION_HASH}
ENV TEMPLATES_COMPILEDIR=${TEMPLATES_COMPILEDIR}

ARG LICENCE=${LICENCE}
ARG DB_HOST=${DB_HOST}
ARG DB_PORT=${DB_PORT}
ARG DB_USERNAME=${DB_USERNAME}
ARG DB_PASSWORD=${DB_PASSWORD}
ARG DB_NAME=${DB_NAME}
ARG DB_TLS_CA=${DB_TLS_CA}
ARG DB_TLS_CA_PATH=${DB_TLS_CA_PATH}
ARG DB_TLS_CERT=${DB_TLS_CERT}
ARG DB_TLS_CIPHER=${DB_TLS_CIPHER}
ARG DB_TLS_KEY=${DB_TLS_KEY}
ARG DB_TLS_VERIFY_CERT=${DB_TLS_VERIFY_CERT}
ARG MYSQL_CHARSET=${MYSQL_CHARSET}
ARG CC_ENCRYPTION_HASH=${CC_ENCRYPTION_HASH}
ARG TEMPLATES_COMPILEDIR=${TEMPLATES_COMPILEDIR}

ARG TYPE=${TYPE}
ENV TYPE=${TYPE}

# Run the script to generate configuration.php only if TYPE != "new"
RUN if [ "$TYPE" != "new" ]; then \
        rm -rf /var/www/html/install; \
        echo "Running generate_config.sh..."; \
        php /usr/local/bin/generate_config.php; \
    else \
        echo "TYPE is new. Skipping configuration generation."; \
    fi

# Install ionCube loader
RUN curl -fsSL "http://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz" -o ioncube.tar.gz \
    && tar -xzf ioncube.tar.gz || { echo "ionCube tar extraction failed"; exit 1; } \
    && mv ioncube/ioncube_loader_lin_8.1.so $(php-config --extension-dir) \
    && rm -Rf ioncube.tar.gz ioncube \
    && docker-php-ext-enable ioncube_loader_lin_8.1 || { echo "ionCube loader enabling failed"; exit 1; }


# Copy cron job definition
COPY docker/cron/crontab /etc/cron.d/whmcs-cron

# Set permissions for cron file
RUN chmod 0644 /etc/cron.d/whmcs-cron

# Apply cron job
RUN crontab /etc/cron.d/whmcs-cron

# Create log file for cron
RUN touch /var/log/cron.log

# Optional: Set Apache to run as www-data user and group
RUN sed -i 's/^User .*/User www-data/' /etc/apache2/apache2.conf \
    && sed -i 's/^Group .*/Group www-data/' /etc/apache2/apache2.conf

# Expose port 80 for Apache
# Expose port 9090 for Swoole
EXPOSE 80 9090

# Start Apache and cron service
CMD cron && apache2ctl -D FOREGROUND & php /var/www/html/swoole_server.php
