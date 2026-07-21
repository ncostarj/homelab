#!/bin/bash

# =============================================================================
# init.sh - Script de gerenciamento de projetos
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS_DIR="$SCRIPT_DIR/apps"
INFRA_DIR="$SCRIPT_DIR/infra"
MODELOS_DIR="$INFRA_DIR/modelos"
NGINX_ENABLED_DIR="$INFRA_DIR/nginx/conf.d/enabled"
NGINX_AVAILABLE_DIR="$INFRA_DIR/nginx/conf.d/available"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# =============================================================================
# Funções utilitárias
# =============================================================================

reiniciar_proxy() {
    echo -e "${YELLOW}🔄 Verificando proxy...${NC}"
    if docker ps --format '{{.Names}}' | grep -q "proxy"; then
        echo -e "   ⏳ Reiniciando proxy..."
        docker compose -f "$INFRA_DIR/docker-compose.yml" restart proxy 2>/dev/null || \
            echo -e "${YELLOW}   ⚠️  Não foi possível reiniciar o proxy automaticamente.${NC}"
        echo -e "${GREEN}   ✅ Proxy reiniciado${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Nenhum container proxy encontrado rodando.${NC}"
    fi
}

# =============================================================================
# Opção 1: Iniciar Novo Projeto
# =============================================================================

iniciar_novo_projeto() {
    echo ""
    echo -e "${CYAN}+------------------------------------------+${NC}"
    echo -e "${CYAN}|   🚀  Novo Projeto                      |${NC}"
    echo -e "${CYAN}+------------------------------------------+${NC}"
    echo ""

    # Passo 1: Nome do projeto
    echo -e "${YELLOW}📝 Passo 1: Nome do projeto${NC}"
    read -p "   Digite o nome do projeto: " NOME_PROJETO

    if [ -z "$NOME_PROJETO" ]; then
        echo -e "${RED}❌ Nome do projeto não pode ser vazio.${NC}"
        exit 1
    fi

    echo -e "${GREEN}   ✅ Projeto: $NOME_PROJETO${NC}"
    echo ""

    # Passo 2: Tecnologia
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

    # Passo 3: Origem do projeto
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
        mkdir -p "$PROJECT_DIR"
        cp -r "$PASTA_ORIGEM"/. "$PROJECT_DIR/"
        echo -e "${GREEN}   ✅ Projeto movido para $PROJECT_DIR${NC}"
    fi

    # Garante que o projeto tenha a pasta src
    if [ -d "$PROJECT_DIR/src" ]; then
        echo -e "${GREEN}   ✅ Pasta src já existe${NC}"
    else
        echo -e "   ⏳ Organizando projeto em src/..."
        mkdir -p "$PROJECT_DIR/__tmp_src"
        find "$PROJECT_DIR" -maxdepth 1 ! -name "__tmp_src" ! -path "$PROJECT_DIR" -exec mv {} "$PROJECT_DIR/__tmp_src/" \;
        mv "$PROJECT_DIR/__tmp_src" "$PROJECT_DIR/src"
        echo -e "${GREEN}   ✅ Conteúdo movido para $PROJECT_DIR/src${NC}"
    fi
    echo ""

    # Passo 4: Criar pastas config/conf.d
    echo -e "${YELLOW}📁 Passo 4: Criando estrutura de configuração${NC}"
    mkdir -p "$PROJECT_DIR/config/conf.d"
    echo -e "${GREEN}   ✅ Pasta config/conf.d criada${NC}"
    echo ""

    # Passo 5: Gerar arquivo Nginx local do projeto
    echo -e "${YELLOW}⚙️  Passo 5: Gerando configuração Nginx do projeto${NC}"
    sed "s/padrao/$NOME_PROJETO/g" "$MODELOS_DIR/padrao.conf" > "$PROJECT_DIR/config/conf.d/$NOME_PROJETO.conf"
    echo -e "${GREEN}   ✅ Arquivo $NOME_PROJETO.conf criado em config/conf.d${NC}"
    echo ""

    # Passo 6: Gerar docker-compose.yml
    echo -e "${YELLOW}🐳 Passo 6: Gerando docker-compose.yml${NC}"

    EXISTING_COMPOSE=""
    if [ -f "$PROJECT_DIR/docker-compose.yml" ] || [ -f "$PROJECT_DIR/docker-compose.yaml" ]; then
        EXISTING_COMPOSE="$PROJECT_DIR"
    elif [ -f "$PROJECT_DIR/src/docker-compose.yml" ] || [ -f "$PROJECT_DIR/src/docker-compose.yaml" ]; then
        EXISTING_COMPOSE="$PROJECT_DIR/src"
    fi

    if [ -n "$EXISTING_COMPOSE" ]; then
        echo -e "${YELLOW}   ⚠️  docker-compose já encontrado em: $EXISTING_COMPOSE${NC}"
        sed "s/padrao/$NOME_PROJETO/g" "$MODELOS_DIR/docker-compose-padrao.yml" > "$PROJECT_DIR/docker-compose.override.yml"
        echo -e "${GREEN}   ✅ docker-compose.override.yml criado (compose existente mantido)${NC}"
    else
        sed "s/padrao/$NOME_PROJETO/g" "$MODELOS_DIR/docker-compose-padrao.yml" > "$PROJECT_DIR/docker-compose.yml"
        echo -e "${GREEN}   ✅ docker-compose.yml criado${NC}"
    fi
    echo ""

    # Passo 7: Adicionar conf no proxy global (Nginx)
    echo -e "${YELLOW}🌐 Passo 7: Adicionando configuração ao proxy global${NC}"
    mkdir -p "$NGINX_ENABLED_DIR"
    sed "s/padrao/$NOME_PROJETO/g" "$MODELOS_DIR/global.conf" > "$NGINX_ENABLED_DIR/$NOME_PROJETO.conf"
    echo -e "${GREEN}   ✅ $NOME_PROJETO.conf adicionado em infra/nginx/conf.d/enabled${NC}"
    echo ""

    # Passo 8: Verificar e reiniciar proxy
    reiniciar_proxy
    echo ""

    # Finalização
    echo -e "${CYAN}+------------------------------------------+${NC}"
    echo -e "${CYAN}|   🎉 Projeto configurado com sucesso!    |${NC}"
    echo -e "${CYAN}+------------------------------------------+${NC}"
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
}

# =============================================================================
# Opção 2: Habilitar Projeto (available → enabled)
# =============================================================================

habilitar_projeto() {
    echo ""
    echo -e "${CYAN}+------------------------------------------+${NC}"
    echo -e "${CYAN}|   ✅  Habilitar Projeto                  |${NC}"
    echo -e "${CYAN}+------------------------------------------+${NC}"
    echo ""

    # Listar projetos disponíveis (desabilitados)
    CONFS=($(ls "$NGINX_AVAILABLE_DIR"/*.conf 2>/dev/null))

    if [ ${#CONFS[@]} -eq 0 ]; then
        echo -e "${YELLOW}   ⚠️  Nenhum projeto desabilitado encontrado em available/.${NC}"
        echo ""
        return
    fi

    echo -e "${YELLOW}   Projetos disponíveis para habilitar:${NC}"
    echo ""
    for i in "${!CONFS[@]}"; do
        CONF_NAME=$(basename "${CONFS[$i]}" .conf)
        echo "   $((i+1))) $CONF_NAME"
    done
    echo ""
    read -p "   Selecione o projeto [1-${#CONFS[@]}]: " PROJ_OPTION

    if ! [[ "$PROJ_OPTION" =~ ^[0-9]+$ ]] || [ "$PROJ_OPTION" -lt 1 ] || [ "$PROJ_OPTION" -gt ${#CONFS[@]} ]; then
        echo -e "${RED}❌ Opção inválida.${NC}"
        exit 1
    fi

    SELECTED_CONF="${CONFS[$((PROJ_OPTION-1))]}"
    CONF_FILENAME=$(basename "$SELECTED_CONF")

    echo -e "   ⏳ Habilitando $CONF_FILENAME..."
    mv "$SELECTED_CONF" "$NGINX_ENABLED_DIR/$CONF_FILENAME"
    echo -e "${GREEN}   ✅ $CONF_FILENAME movido para enabled/${NC}"
    echo ""

    reiniciar_proxy
    echo ""
}

# =============================================================================
# Opção 3: Desabilitar Projeto (enabled → available)
# =============================================================================

desabilitar_projeto() {
    echo ""
    echo -e "${CYAN}+------------------------------------------+${NC}"
    echo -e "${CYAN}|   ⛔  Desabilitar Projeto                |${NC}"
    echo -e "${CYAN}+------------------------------------------+${NC}"
    echo ""

    # Listar projetos habilitados
    CONFS=($(ls "$NGINX_ENABLED_DIR"/*.conf 2>/dev/null))

    if [ ${#CONFS[@]} -eq 0 ]; then
        echo -e "${YELLOW}   ⚠️  Nenhum projeto habilitado encontrado em enabled/.${NC}"
        echo ""
        return
    fi

    echo -e "${YELLOW}   Projetos habilitados:${NC}"
    echo ""
    for i in "${!CONFS[@]}"; do
        CONF_NAME=$(basename "${CONFS[$i]}" .conf)
        echo "   $((i+1))) $CONF_NAME"
    done
    echo ""
    read -p "   Selecione o projeto para desabilitar [1-${#CONFS[@]}]: " PROJ_OPTION

    if ! [[ "$PROJ_OPTION" =~ ^[0-9]+$ ]] || [ "$PROJ_OPTION" -lt 1 ] || [ "$PROJ_OPTION" -gt ${#CONFS[@]} ]; then
        echo -e "${RED}❌ Opção inválida.${NC}"
        exit 1
    fi

    SELECTED_CONF="${CONFS[$((PROJ_OPTION-1))]}"
    CONF_FILENAME=$(basename "$SELECTED_CONF")

    echo -e "   ⏳ Desabilitando $CONF_FILENAME..."
    mkdir -p "$NGINX_AVAILABLE_DIR"
    mv "$SELECTED_CONF" "$NGINX_AVAILABLE_DIR/$CONF_FILENAME"
    echo -e "${GREEN}   ✅ $CONF_FILENAME movido para available/${NC}"
    echo ""

    reiniciar_proxy
    echo ""
}

# =============================================================================
# Menu Principal
# =============================================================================

echo ""
echo -e "${CYAN}+------------------------------------------+${NC}"
echo -e "${CYAN}|   🛠️   Gerenciador de Projetos            |${NC}"
echo -e "${CYAN}+------------------------------------------+${NC}"
echo ""
echo "   1) Iniciar Novo Projeto"
echo "   2) Habilitar Projeto"
echo "   3) Desabilitar Projeto"
echo ""
read -p "   Selecione uma opção [1-3]: " MENU_OPTION

case $MENU_OPTION in
    1) iniciar_novo_projeto ;;
    2) habilitar_projeto ;;
    3) desabilitar_projeto ;;
    *)
        echo -e "${RED}❌ Opção inválida.${NC}"
        exit 1
        ;;
esac
