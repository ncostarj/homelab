#!/bin/bash

# =============================================================================
# init.sh - Script de inicialização de novos projetos Fintools
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS_DIR="$SCRIPT_DIR/apps"
INFRA_DIR="$SCRIPT_DIR/infra"
MODELOS_DIR="$INFRA_DIR/modelos"
NGINX_ENABLED_DIR="$INFRA_DIR/nginx/conf.d/enabled"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🚀 Homelab - Novo Projeto              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# ---------------------------------------------------------------------------
# Passo 1: Nome do projeto
# ---------------------------------------------------------------------------
echo -e "${YELLOW}📝 Passo 1: Nome do projeto${NC}"
read -p "   Digite o nome do projeto: " NOME_PROJETO

if [ -z "$NOME_PROJETO" ]; then
    echo -e "${RED}❌ Nome do projeto não pode ser vazio.${NC}"
    exit 1
fi

echo -e "${GREEN}   ✅ Projeto: $NOME_PROJETO${NC}"
echo ""

# ---------------------------------------------------------------------------
# Passo 2: Tecnologia
# ---------------------------------------------------------------------------
echo -e "${YELLOW}🛠️  Passo 2: Tecnologia${NC}"
echo "   Selecione a tecnologia:"
echo "   1) Front Vue"
echo "   2) Front Nuxt (Vue)"
echo "   3) Back PHP"
echo "   4) Back Laravel (PHP)"
echo "   5) Back Nodejs"
echo "   6) Back Express (Nodejs)"
echo ""
read -p "   Opção [1-6]: " TECH_OPTION

case $TECH_OPTION in
    1) TECNOLOGIA="Front Vue" ;;
    2) TECNOLOGIA="Front Nuxt (Vue)" ;;
    3) TECNOLOGIA="Back PHP" ;;
    4) TECNOLOGIA="Back Laravel (PHP)" ;;
    5) TECNOLOGIA="Back Nodejs" ;;
    6) TECNOLOGIA="Back Express (Nodejs)" ;;
    *)
        echo -e "${RED}❌ Opção inválida.${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}   ✅ Tecnologia: $TECNOLOGIA${NC}"
echo ""

# ---------------------------------------------------------------------------
# Passo 3: Versionamento
# ---------------------------------------------------------------------------
echo -e "${YELLOW}📦 Passo 3: Origem do projeto${NC}"
read -p "   O projeto está versionado no git? (s/n): " VERSIONADO

PROJECT_DIR="$APPS_DIR/$NOME_PROJETO"

if [ "$VERSIONADO" = "s" ] || [ "$VERSIONADO" = "S" ]; then
    read -p "   URL do repositório git: " GIT_URL

    if [ -z "$GIT_URL" ]; then
        echo -e "${RED}❌ URL do repositório não pode ser vazia.${NC}"
        exit 1
    fi

    echo -e "   ⏳ Clonando repositório..."
    git clone "$GIT_URL" "$PROJECT_DIR"
    echo -e "${GREEN}   ✅ Repositório clonado em $PROJECT_DIR${NC}"
else
    read -p "   Caminho da pasta do projeto: " PASTA_ORIGEM

    if [ ! -d "$PASTA_ORIGEM" ]; then
        echo -e "${RED}❌ Pasta não encontrada: $PASTA_ORIGEM${NC}"
        exit 1
    fi

    echo -e "   ⏳ Movendo projeto..."
    mkdir -p "$PROJECT_DIR/src"
    cp -r "$PASTA_ORIGEM"/. "$PROJECT_DIR/src/"
    echo -e "${GREEN}   ✅ Projeto movido para $PROJECT_DIR/src${NC}"
fi
echo ""

# ---------------------------------------------------------------------------
# Passo 4: Criar pastas config/conf.d
# ---------------------------------------------------------------------------
echo -e "${YELLOW}📁 Passo 4: Criando estrutura de configuração${NC}"
mkdir -p "$PROJECT_DIR/config/conf.d"
echo -e "${GREEN}   ✅ Pasta config/conf.d criada${NC}"
echo ""

# ---------------------------------------------------------------------------
# Passo 5: Gerar arquivo Nginx local do projeto
# ---------------------------------------------------------------------------
echo -e "${YELLOW}⚙️  Passo 5: Gerando configuração Nginx do projeto${NC}"
sed "s/padrao/$NOME_PROJETO/g" "$MODELOS_DIR/padrao.conf" > "$PROJECT_DIR/config/conf.d/$NOME_PROJETO.conf"
echo -e "${GREEN}   ✅ Arquivo $NOME_PROJETO.conf criado em config/conf.d${NC}"
echo ""

# ---------------------------------------------------------------------------
# Passo 6: Gerar docker-compose.yml
# ---------------------------------------------------------------------------
echo -e "${YELLOW}🐳 Passo 6: Gerando docker-compose.yml${NC}"
sed "s/padrao/$NOME_PROJETO/g" "$MODELOS_DIR/docker-compose-padrao.yml" > "$PROJECT_DIR/docker-compose.yml"
echo -e "${GREEN}   ✅ docker-compose.yml criado${NC}"
echo ""

# ---------------------------------------------------------------------------
# Passo 7: Adicionar conf no proxy global (Nginx)
# ---------------------------------------------------------------------------
echo -e "${YELLOW}🌐 Passo 7: Adicionando configuração ao proxy global${NC}"
mkdir -p "$NGINX_ENABLED_DIR"
sed "s/padrao/$NOME_PROJETO/g" "$MODELOS_DIR/global.conf" > "$NGINX_ENABLED_DIR/$NOME_PROJETO.conf"
echo -e "${GREEN}   ✅ $NOME_PROJETO.conf adicionado em infra/nginx/conf.d/enabled${NC}"
echo ""

# ---------------------------------------------------------------------------
# Passo 8: Verificar e reiniciar proxy
# ---------------------------------------------------------------------------
echo -e "${YELLOW}🔄 Passo 8: Verificando proxy${NC}"

if docker ps --format '{{.Names}}' | grep -q "proxy"; then
    echo -e "   ⏳ Reiniciando proxy..."
    docker compose -f "$INFRA_DIR/docker-compose.yml" restart proxy 2>/dev/null || \
        docker-compose -f "$INFRA_DIR/docker-compose.yml" restart proxy 2>/dev/null || \
        echo -e "${YELLOW}   ⚠️  Não foi possível reiniciar o proxy automaticamente.${NC}"
    echo -e "${GREEN}   ✅ Proxy reiniciado${NC}"
else
    echo -e "${YELLOW}   ⚠️  Nenhum container proxy encontrado rodando.${NC}"
fi
echo ""

# ---------------------------------------------------------------------------
# Finalização
# ---------------------------------------------------------------------------
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🎉 Projeto configurado com sucesso!   ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📋 Resumo:${NC}"
echo -e "   Projeto:     $NOME_PROJETO"
echo -e "   Tecnologia:  $TECNOLOGIA"
echo -e "   Local:       $PROJECT_DIR"
echo ""
echo -e "${CYAN}▶ Para levantar o container, execute:${NC}"
echo ""
echo -e "   cd $PROJECT_DIR && docker compose up -d"
echo ""
