#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║      Desinstalador de Containers       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${RED}${BOLD}ATENÇÃO: Este script irá remover TUDO!${NC}"
echo ""
echo -e "${YELLOW}Isso inclui:${NC}"
echo "  • Containers (n8n, caddy, postgres)"
echo "  • Imagens Docker"
echo "  • Volumes e dados persistidos"
echo "  • Rede Docker (docker-network)"
echo "  • Configurações e credenciais"
echo ""
read -p "Tem certeza que deseja continuar? (y/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}Operação cancelada.${NC}"
    echo ""
    exit 0
fi

echo ""
echo -e "${YELLOW}► Parando containers...${NC}"
docker stop n8n caddy postgres 2>/dev/null || true
echo -e "${GREEN}  ✓ Containers parados${NC}"

echo -e "${YELLOW}► Removendo containers...${NC}"
docker rm n8n caddy postgres 2>/dev/null || true
echo -e "${GREEN}  ✓ Containers removidos${NC}"

echo -e "${YELLOW}► Removendo volumes Docker...${NC}"
docker volume ls -q | grep -E 'n8n|postgres|caddy' | xargs -r docker volume rm 2>/dev/null || true
echo -e "${GREEN}  ✓ Volumes removidos${NC}"

echo -e "${YELLOW}► Removendo imagens Docker...${NC}"
docker rmi n8nio/n8n:latest 2>/dev/null || true
docker rmi postgres:16-alpine 2>/dev/null || true
docker rmi caddy:latest 2>/dev/null || true
echo -e "${GREEN}  ✓ Imagens removidas${NC}"

echo -e "${YELLOW}► Removendo rede...${NC}"
docker network rm docker-network 2>/dev/null || true
echo -e "${GREEN}  ✓ Rede removida${NC}"

echo -e "${YELLOW}► Removendo dados persistidos...${NC}"
rm -rf /opt/dockers/data
rm -rf /opt/dockers/configs/*
rm -f /opt/dockers/templates/Caddyfile
echo -e "${GREEN}  ✓ Dados removidos${NC}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       Desinstalação Concluída!         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Todos os containers, imagens, volumes e dados foram removidos."
echo ""
echo -e "Para reinstalar, execute: ${GREEN}./install.sh${NC}"
echo ""
