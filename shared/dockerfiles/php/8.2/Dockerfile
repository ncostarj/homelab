FROM php:8.2-fpm

# UID/GID do usuário do host (podem ser sobrescritos na build)
ARG UID=1000
ARG GID=1000
ARG USER=developer

# Usuário padrão
RUN groupadd -g ${GID} ${USER} \
    && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USER}

# Home do usuário
ENV HOME=/home/${USER}

# Workspace genérico para qualquer projeto
WORKDIR ${HOME}/workspace

# Dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    zip \
    libicu-dev \
    libzip-dev \
    libxml2-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    && rm -rf /var/lib/apt/lists/*

# Extensões PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) \
        bcmath \
        gd \
        intl \
        mbstring \
        opcache \
        pdo_mysql \
        xml \
        zip

# MongoDB
RUN pecl install mongodb-1.21.1 \
    && docker-php-ext-enable mongodb

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Node.js 24.x
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest yarn pnpm

# Garantir que o usuário seja dono da sua HOME
RUN chown -R ${USER}:${USER} ${HOME}

# Testes
RUN php -v \
    && composer --version \
    && node --version \
    && npm --version \
    && yarn --version \
    && pnpm --version

USER ${USER}

CMD ["php-fpm"]