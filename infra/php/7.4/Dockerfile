FROM php:7.4-fpm

# Install base dependencies
RUN apt-get update && apt-get install -y \
    iputils-ping \
    net-tools \
    git \
    locales \
    curl \
    openssl \
    libpng-dev \
    libonig-dev \    
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    libssl-dev \
    libicu-dev \
    libpq-dev \
    gnupg \  
    imagemagick \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libreadline-dev \
    # php-xml \
    # php-common \
    vim \
    rsyslog \ 
    && rm -rf /var/lib/apt/lists/*

# RUN sed -i -- 's/# pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/g' /etc/locale.gen \
#     && locale-gen \
#     && sed -i -- 's/Etc\/UTC/America\/Sao_Paulo/g' /etc/timezone \
#     && sed -i -- 's/# alias ll/alias ll/g' /root/.bashrc \
#     && unlink /etc/localtime \
#     && ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
#     # && sed -i -- 's/localhost/localhost,big.server.com/g' /etc/hosts 

# ENV LC_ALL pt_BR.UTF8
# ENV LANG pt_BR.UTF8
# ENV LANGUAGE pt_BR:pt:en

RUN docker-php-ext-configure \
    pdo_mysql \
    --with-pdo-mysql=mysqlnd

RUN docker-php-ext-configure \
    gd \
    --with-freetype --with-jpeg

RUN docker-php-ext-install \
    intl \
    bcmath \
    gd \
    iconv \
    mbstring \
    pdo \   
    pcntl \
    json \  
    pdo_mysql \ 
    tokenizer \
    zip \
    xml \
    opcache

# mongodb
RUN pecl install mongodb-1.20.1
RUN echo "extension=mongodb.so" > $PHP_INI_DIR/conf.d/mongodb.ini

# RUN docker-php-ext-enable gd mongodb

# Installing composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# RUN composer global require laravel/installer

# Change uid and gid of apache to docker user uid/gid
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

USER www-data

RUN composer --version