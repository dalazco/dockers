#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

REPO_URL="https://github.com/dalazco/dockers.git"
INSTALL_DIR="/opt/dockers"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Instalador Docker Automatizado     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Verificar se é root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}✗ Este script precisa ser executado como root${NC}"
    echo -e "${YELLOW}  Use: curl -fsSL https://raw.githubusercontent.com/dalazco/dockers/main/install.sh | sudo bash${NC}"
    echo ""
    exit 1
fi

# Verificar se git está instalado
if ! command -v git &> /dev/null; then
    echo -e "${CYAN}► Instalando Git...${NC}"
    apt-get update -qq
    apt-get install -y -qq git
    echo -e "${GREEN}  ✓ Git instalado${NC}"
fi

# Verificar se o diretório já existe
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠  Diretório $INSTALL_DIR já existe${NC}"
    read -p "Deseja remover e reinstalar? (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        echo -e "${GREEN}  ✓ Diretório removido${NC}"
    else
        echo -e "${YELLOW}Usando diretório existente...${NC}"
    fi
fi

# Criar diretório e clonar repositório
if [ ! -d "$INSTALL_DIR/.git" ]; then
    echo -e "${CYAN}► Clonando repositório...${NC}"
    mkdir -p "$INSTALL_DIR"
    git clone -q "$REPO_URL" "$INSTALL_DIR"
    echo -e "${GREEN}  ✓ Repositório clonado${NC}"
else
    echo -e "${CYAN}► Atualizando repositório...${NC}"
    cd "$INSTALL_DIR"
    git pull -q origin main
    echo -e "${GREEN}  ✓ Repositório atualizado${NC}"
fi

# Mudar para o diretório de instalação
cd "$INSTALL_DIR"

# Dar permissão de execução aos scripts
chmod +x setup.sh uninstall.sh scripts/*/install.sh 2>/dev/null || true

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       Preparação Concluída!        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Iniciando menu de instalação...${NC}"
echo ""

# Executar o menu de instalação
exec ./setup.sh
