FROM php:8.3-apache

#Instalar dependências do sistema e extensões PHP necessárias para o Laravel
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

#Habilitar o mod_rewrite do Apache (essencial para o Laravel)
RUN a2enmod rewrite

#Instalar o Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

#Instalar o Node.js e NPM (necessário para compilar o Jetstream)
RUN curl -sL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y openssl nodejs

WORKDIR /var/www/html

COPY . .

#Instalar dependências do PHP e do Node, e compilar os assets do Jetstream
RUN composer install --no-interaction --optimize-autoloader --no-dev
RUN npm install && npm run build

#Ajustar permissões para o Apache conseguir ler/escrever no Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

#Ajustar a pasta pública do Apache para apontar para a pasta /public do Laravel
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf

EXPOSE 80

CMD ["apache2-foreground"]