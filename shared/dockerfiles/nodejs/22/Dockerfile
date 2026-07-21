FROM node:22-bookworm

ARG USER=node

# Home do usuário
ENV HOME=/home/${USER}

# Dependências do sistema
RUN apt-get update && \
    apt-get install -y \
        git \
        curl \
        wget \
        unzip \
        zip \
        vim \
        bash-completion \
        procps \
        openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Habilita o Corepack (pnpm e yarn)
RUN corepack enable

# Usuário padrão da imagem oficial do Node
USER ${USER}

# Workspace padrão
WORKDIR ${HOME}/workspace