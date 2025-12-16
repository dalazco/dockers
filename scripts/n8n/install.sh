#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"
N8N_ENCRYPTION_KEY="${N8N_ENCRYPTION_KEY}"
N8N_JWT_SECRET="${N8N_JWT_SECRET}"
DOMAIN="${DOMAIN:-localhost}"
SERVER_IP="${SERVER_IP:-localhost}"

echo -e "${CYAN}Configurando n8n...${NC}"

if docker ps -a | grep -q "^n8n$" 2>/dev/null; then
    echo "Container n8n já existe. Removendo..."
    docker stop n8n 2>/dev/null || true
    docker rm n8n 2>/dev/null || true
fi

mkdir -p /opt/dockers/data/n8n
chown -R 1000:1000 /opt/dockers/data/n8n

DB_TYPE="postgresdb"
DB_HOST="postgres"
DB_PORT="5432"
DB_DATABASE="n8n_db"
DB_USER="postgres"

# Configurar porta baseado se tem Caddy ou não
if [ "$DOMAIN" = "localhost" ]; then
    # Sem Caddy - expor porta 5678
    PORT_ARGS="-p 5678:5678"
    N8N_HOST="${SERVER_IP}"
    N8N_PORT="5678"
    N8N_PROTOCOL="http"
    WEBHOOK_URL="http://${SERVER_IP}:5678/"
else
    # Com Caddy - não expor porta
    PORT_ARGS=""
    N8N_HOST="${DOMAIN}"
    N8N_PORT="443"
    N8N_PROTOCOL="https"
    WEBHOOK_URL="https://${DOMAIN}/"
fi

docker run -d \
    --name n8n \
    --network docker-network \
    --restart unless-stopped \
    ${PORT_ARGS} \
    -e DB_TYPE=${DB_TYPE} \
    -e DB_POSTGRESDB_HOST=${DB_HOST} \
    -e DB_POSTGRESDB_PORT=${DB_PORT} \
    -e DB_POSTGRESDB_DATABASE=${DB_DATABASE} \
    -e DB_POSTGRESDB_USER=${DB_USER} \
    -e DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD} \
    -e N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY} \
    -e N8N_USER_MANAGEMENT_JWT_SECRET=${N8N_JWT_SECRET} \
    -e N8N_HOST=${N8N_HOST} \
    -e N8N_PORT=${N8N_PORT} \
    -e N8N_PROTOCOL=${N8N_PROTOCOL} \
    -e WEBHOOK_URL=${WEBHOOK_URL} \
    -e N8N_EMAIL_MODE=smtp \
    -e GENERIC_TIMEZONE=America/Sao_Paulo \
    -e N8N_METRICS=true \
    -v /opt/dockers/data/n8n:/home/node/.n8n \
    n8nio/n8n:latest

echo -e "${YELLOW}Aguardando n8n inicializar...${NC}"
sleep 15

if docker ps | grep -q "^n8n$"; then
    echo -e "${GREEN}✓ n8n configurado e em execução${NC}"
else
    echo -e "${YELLOW}⚠ Verificar logs: docker logs n8n${NC}"
fi

echo ""
echo -e "${GREEN}n8n Configurado:${NC}"
echo "  Container: n8n"
echo "  Host: ${N8N_HOST}"
echo "  Protocol: ${N8N_PROTOCOL}"
echo "  Database: ${DB_DATABASE}@${DB_HOST}"
echo "  Network: docker-network"
echo "  Volume: /opt/dockers/data/n8n"
