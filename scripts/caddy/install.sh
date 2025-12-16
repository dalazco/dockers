#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

DOMAIN="${DOMAIN:-localhost}"
SSL_EMAIL="${SSL_EMAIL:-admin@example.com}"

echo -e "${CYAN}Configurando Caddy...${NC}"

if docker ps -a | grep -q "^caddy$" 2>/dev/null; then
    echo "Container Caddy já existe. Removendo..."
    docker stop caddy 2>/dev/null || true
    docker rm caddy 2>/dev/null || true
fi

mkdir -p /opt/dockers/data/caddy/{data,config}

cat > /opt/dockers/templates/Caddyfile <<EOF
{
    email ${SSL_EMAIL}
    auto_https on
}

${DOMAIN} {
    reverse_proxy n8n:5678 {
        header_up Host {host}
        header_up X-Real-IP {remote}
        header_up X-Forwarded-For {remote}
        header_up X-Forwarded-Proto {scheme}
    }
    
    encode gzip
    
    log {
        output file /var/log/caddy/access.log
        format json
    }
}
EOF

docker run -d \
    --name caddy \
    --network docker-network \
    --restart unless-stopped \
    -p 80:80 \
    -p 443:443 \
    -p 443:443/udp \
    -v /opt/dockers/templates/Caddyfile:/etc/caddy/Caddyfile \
    -v /opt/dockers/data/caddy/data:/data \
    -v /opt/dockers/data/caddy/config:/config \
    caddy:latest

echo -e "${YELLOW}Aguardando Caddy inicializar...${NC}"
sleep 5

if docker ps | grep -q "^caddy$"; then
    echo -e "${GREEN}✓ Caddy configurado e em execução${NC}"
else
    echo -e "${YELLOW}⚠ Verificar logs: docker logs caddy${NC}"
fi

echo ""
echo -e "${GREEN}Caddy Configurado:${NC}"
echo "  Container: caddy"
echo "  Domain: ${DOMAIN}"
echo "  Ports: 80, 443 (HTTP/HTTPS)"
echo "  SSL: Automático (Let's Encrypt)"
echo "  Network: docker-network"
echo "  Config: /opt/dockers/templates/Caddyfile"
