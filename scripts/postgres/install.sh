#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"

echo -e "${CYAN}Configurando PostgreSQL...${NC}"

if docker ps -a | grep -q "^postgres$" 2>/dev/null; then
    echo "Container PostgreSQL já existe. Removendo..."
    docker stop postgres 2>/dev/null || true
    docker rm postgres 2>/dev/null || true
fi

mkdir -p /opt/dockers/data/postgres

# Configurações otimizadas para PostgreSQL
docker run -d \
    --name postgres \
    --network docker-network \
    --restart unless-stopped \
    -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
    -e POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=C" \
    -e PGDATA=/var/lib/postgresql/data/pgdata \
    -v /opt/dockers/data/postgres:/var/lib/postgresql/data \
    postgres:16-alpine \
    postgres \
    -c shared_buffers=256MB \
    -c max_connections=200 \
    -c effective_cache_size=1GB \
    -c maintenance_work_mem=64MB \
    -c checkpoint_completion_target=0.9 \
    -c wal_buffers=16MB \
    -c default_statistics_target=100 \
    -c random_page_cost=1.1 \
    -c effective_io_concurrency=200 \
    -c work_mem=2MB \
    -c min_wal_size=1GB \
    -c max_wal_size=4GB

echo -e "${YELLOW}Aguardando PostgreSQL inicializar...${NC}"
sleep 10

# Criar database n8n se o n8n for instalado
if docker exec postgres pg_isready -U postgres &> /dev/null; then
    echo -e "${GREEN}✓ PostgreSQL inicializado${NC}"
    
    # Criar database para n8n
    docker exec postgres psql -U postgres -c "CREATE DATABASE n8n_db;" 2>/dev/null || true
    echo -e "${GREEN}✓ Database 'n8n_db' criada${NC}"
else
    echo -e "${YELLOW}⚠ PostgreSQL pode estar inicializando...${NC}"
fi

echo ""
echo -e "${GREEN}PostgreSQL Configurado:${NC}"
echo "  Container: postgres"
echo "  User: postgres"
echo "  Databases: postgres, n8n_db"
echo "  Network: docker-network"
echo "  Volume: /opt/dockers/data/postgres"
