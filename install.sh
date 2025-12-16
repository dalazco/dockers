#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

INSTALL_POSTGRES=false
INSTALL_N8N=false
INSTALL_CADDY=false
INSTALL_DIR="/opt/dockers"
REPO_URL="https://github.com/dalazco/dockers.git"

# Verificar se está rodando via curl/wget (stdin não é terminal) e não foi bootstrapped
if [ ! -t 0 ] && [ -z "$DOCKERS_BOOTSTRAPPED" ]; then
    REMOTE_INSTALL=true
else
    REMOTE_INSTALL=false
fi

generate_password() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 25 | head -n 1
}

generate_token() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 128 | head -n 1
}

show_header() {
    clear
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Instalador Automático de Dockers     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}✗ Este script precisa ser executado como root${NC}"
        echo -e "${YELLOW}  Use: curl -fsSL https://raw.githubusercontent.com/dalazco/dockers/main/install.sh | sudo bash${NC}"
        echo ""
        exit 1
    fi
}

check_docker_installed() {
    if command -v docker &> /dev/null; then
        return 0
    else
        return 1
    fi
}

check_component_installed() {
    local component=$1
    if docker ps -a --format "{{.Names}}" 2>/dev/null | grep -q "^${component}$"; then
        return 0
    else
        return 1
    fi
}

show_menu() {
    show_header
    
    if ! check_docker_installed; then
        echo -e "${YELLOW}⚠  Docker será instalado automaticamente${NC}"
    else
        echo -e "${GREEN}✓ Docker já está instalado${NC}"
    fi
    echo ""
    
    echo -e "${CYAN}${BOLD}Selecione os componentes para instalar:${NC}"
    echo ""
    
    # PostgreSQL - sempre mostra (permite múltiplas instalações)
    local postgres_installed=false
    if check_component_installed "postgres"; then
        postgres_installed=true
    fi
    
    if [ "$postgres_installed" = true ]; then
        if [ "$INSTALL_POSTGRES" = true ]; then
            echo -e "  ${GREEN}[X]${NC} 1. PostgreSQL - Banco de dados ${GREEN}✓ instalado${NC}"
        else
            echo -e "  [ ] 1. PostgreSQL - Banco de dados ${GREEN}✓ instalado${NC}"
        fi
    else
        if [ "$INSTALL_POSTGRES" = true ]; then
            echo -e "  ${GREEN}[X]${NC} 1. PostgreSQL - Banco de dados"
        else
            echo -e "  [ ] 1. PostgreSQL - Banco de dados"
        fi
    fi
    
    # n8n - oculta se já instalado
    if check_component_installed "n8n"; then
        echo -e "      ${GREEN}✓ n8n - Automação de workflows (já instalado)${NC}"
    else
        if [ "$INSTALL_N8N" = true ]; then
            echo -e "  ${GREEN}[X]${NC} 2. n8n - Automação de workflows ${YELLOW}(requer PostgreSQL)${NC}"
        else
            echo -e "  [ ] 2. n8n - Automação de workflows ${YELLOW}(requer PostgreSQL)${NC}"
        fi
    fi
    
    # Caddy - oculta se já instalado
    if check_component_installed "caddy"; then
        echo -e "      ${GREEN}✓ Caddy - Reverse proxy com HTTPS (já instalado)${NC}"
    else
        if [ "$INSTALL_CADDY" = true ]; then
            echo -e "  ${GREEN}[X]${NC} 3. Caddy - Reverse proxy com HTTPS"
        else
            echo -e "  [ ] 3. Caddy - Reverse proxy com HTTPS"
        fi
    fi
    
    echo ""
    echo -e "${CYAN}Opções:${NC}"
    
    # Ajustar opções baseado no que está disponível
    local available_options="1"
    if ! check_component_installed "n8n"; then
        available_options="${available_options}-2"
    fi
    if ! check_component_installed "caddy"; then
        if [ "$available_options" = "1" ]; then
            available_options="${available_options}, 3"
        else
            available_options="${available_options}, 3"
        fi
    fi
    
    echo -e "  ${GREEN}[${available_options}]${NC} Marcar/desmarcar componente"
    
    # Só mostra opção A se n8n e caddy não estiverem instalados
    if ! check_component_installed "n8n" && ! check_component_installed "caddy"; then
        echo -e "  ${GREEN}[A]${NC}   Stack completa (PostgreSQL + n8n + Caddy)"
    fi
    
    echo -e "  ${GREEN}[I]${NC}   Instalar selecionados"
    echo -e "  ${RED}[Q]${NC}   Sair"
    echo ""
    echo -n "Escolha: "
}

select_components() {
    while true; do
        show_menu
        read -r option </dev/tty
        
        case $option in
            1)
                # PostgreSQL pode ter múltiplas instalações
                INSTALL_POSTGRES=$([ "$INSTALL_POSTGRES" = true ] && echo false || echo true)
                ;;
            2)
                # n8n - verificar se já está instalado
                if check_component_installed "n8n"; then
                    show_header
                    echo -e "${YELLOW}⚠  n8n já está instalado!${NC}"
                    echo ""
                    echo "Para reinstalar, primeiro desinstale usando:"
                    echo -e "  ${CYAN}cd /opt/dockers && ./uninstall.sh${NC}"
                    echo ""
                    read -p "Pressione ENTER para continuar..." </dev/tty
                    continue
                fi
                INSTALL_N8N=$([ "$INSTALL_N8N" = true ] && echo false || echo true)
                if [ "$INSTALL_N8N" = true ]; then
                    INSTALL_POSTGRES=true
                fi
                ;;
            3)
                # Caddy - verificar se já está instalado
                if check_component_installed "caddy"; then
                    show_header
                    echo -e "${YELLOW}⚠  Caddy já está instalado!${NC}"
                    echo ""
                    echo "Para reinstalar, primeiro desinstale usando:"
                    echo -e "  ${CYAN}cd /opt/dockers && ./uninstall.sh${NC}"
                    echo ""
                    read -p "Pressione ENTER para continuar..." </dev/tty
                    continue
                fi
                INSTALL_CADDY=$([ "$INSTALL_CADDY" = true ] && echo false || echo true)
                ;;
            [Aa])
                # Verificar se n8n ou caddy já estão instalados
                local blocked=false
                local blocked_msg=""
                
                if check_component_installed "n8n"; then
                    blocked=true
                    blocked_msg="${blocked_msg}n8n "
                fi
                if check_component_installed "caddy"; then
                    blocked=true
                    blocked_msg="${blocked_msg}caddy "
                fi
                
                if [ "$blocked" = true ]; then
                    show_header
                    echo -e "${YELLOW}⚠  Componentes já instalados: ${blocked_msg}${NC}"
                    echo ""
                    echo "Para reinstalar, primeiro desinstale usando:"
                    echo -e "  ${CYAN}cd /opt/dockers && ./uninstall.sh${NC}"
                    echo ""
                    read -p "Pressione ENTER para continuar..." </dev/tty
                    continue
                fi
                
                INSTALL_POSTGRES=true
                INSTALL_N8N=true
                INSTALL_CADDY=true
                ;;
            [Ii])
                # Verificar se tem componentes selecionados
                if [ "$INSTALL_POSTGRES" = false ] && [ "$INSTALL_N8N" = false ] && [ "$INSTALL_CADDY" = false ]; then
                    show_header
                    echo -e "${RED}✗ Selecione pelo menos um componente!${NC}"
                    echo ""
                    read -p "Pressione ENTER para continuar..." </dev/tty
                    continue
                fi
                
                # Verificar se está tentando instalar n8n ou caddy já instalados
                local blocked=false
                local blocked_msg=""
                
                if [ "$INSTALL_N8N" = true ] && check_component_installed "n8n"; then
                    blocked=true
                    blocked_msg="${blocked_msg}n8n "
                fi
                if [ "$INSTALL_CADDY" = true ] && check_component_installed "caddy"; then
                    blocked=true
                    blocked_msg="${blocked_msg}caddy "
                fi
                
                if [ "$blocked" = true ]; then
                    show_header
                    echo -e "${RED}✗ Não é possível instalar componentes já existentes!${NC}"
                    echo ""
                    echo -e "Componentes bloqueados: ${YELLOW}${blocked_msg}${NC}"
                    echo ""
                    echo "Para reinstalar, primeiro desinstale usando:"
                    echo -e "  ${CYAN}cd /opt/dockers && ./uninstall.sh${NC}"
                    echo ""
                    read -p "Pressione ENTER para continuar..." </dev/tty
                    continue
                fi
                
                break
                ;;
            [Qq])
                echo ""
                echo -e "${YELLOW}Instalação cancelada.${NC}"
                exit 0
                ;;
            *)
                ;;
        esac
    done
}

install_docker() {
    echo ""
    echo -e "${CYAN}[Docker]${NC} Verificando processos apt..."
    
    local wait_count=0
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        if [ $wait_count -eq 0 ]; then
            echo -e "${YELLOW}⏳ Aguardando outros processos apt finalizarem...${NC}"
        fi
        sleep 5
        wait_count=$((wait_count + 1))
        if [ $wait_count -gt 24 ]; then
            echo -e "${RED}✗ Timeout aguardando liberação do apt${NC}"
            exit 1
        fi
    done
    
    echo -e "${CYAN}[Docker]${NC} Baixando instalador..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    
    echo -e "${CYAN}[Docker]${NC} Instalando..."
    sh get-docker.sh
    rm get-docker.sh
    
    systemctl enable docker
    systemctl start docker
    
    echo -e "${GREEN}✓ Docker instalado${NC}"
}

create_network() {
    if ! docker network ls | grep -q "docker-network"; then
        docker network create docker-network
        echo -e "${GREEN}✓ Rede 'docker-network' criada${NC}"
    else
        echo -e "${GREEN}✓ Rede 'docker-network' já existe${NC}"
    fi
}

get_server_ip() {
    # Tentar obter IP público primeiro
    local public_ip=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 icanhazip.com 2>/dev/null)
    
    if [ -n "$public_ip" ]; then
        echo "$public_ip"
    else
        # Fallback para IP local
        hostname -I | awk '{print $1}'
    fi
}

get_user_input() {
    echo ""
    echo -e "${CYAN}${BOLD}Configuração:${NC}"
    echo ""
    
    # Obter IP do servidor
    echo -e "${YELLOW}Detectando IP do servidor...${NC}"
    SERVER_IP=$(get_server_ip)
    export SERVER_IP
    echo -e "${GREEN}✓ IP detectado: ${SERVER_IP}${NC}"
    echo ""
    
    if [ "$INSTALL_CADDY" = true ]; then
        read -p "Domínio para acesso (ex: n8n.seudominio.com): " DOMAIN </dev/tty
        read -p "Email para certificado SSL: " SSL_EMAIL </dev/tty
        export DOMAIN
        export SSL_EMAIL
    fi
    
    # Gerar senhas automaticamente
    echo -e "${YELLOW}Gerando senhas e tokens de segurança...${NC}"
    export POSTGRES_PASSWORD=$(generate_password)
    
    if [ "$INSTALL_N8N" = true ]; then
        export N8N_ENCRYPTION_KEY=$(generate_token)
        export N8N_JWT_SECRET=$(generate_token)
    fi
    
    # Salvar credenciais em arquivo
    mkdir -p /opt/dockers/configs
    
    cat > /opt/dockers/configs/credentials.txt <<EOF
================================================================================
CREDENCIAIS - Gerado em $(date '+%d/%m/%Y às %H:%M:%S')
MANTENHA ESTE ARQUIVO SEGURO E PRIVADO!
================================================================================

EOF

    if [ "$INSTALL_POSTGRES" = true ]; then
        cat >> /opt/dockers/configs/credentials.txt <<EOF
PostgreSQL:
  Container: postgres
  Database: postgres
  User: postgres
  Password: ${POSTGRES_PASSWORD}
  Host: postgres (interno na rede docker-network)
  Port: 5432

EOF
    fi

    if [ "$INSTALL_N8N" = true ]; then
        cat >> /opt/dockers/configs/credentials.txt <<EOF
n8n:
  Container: n8n
  Database: n8n_db (dentro do PostgreSQL)
  Encryption Key: ${N8N_ENCRYPTION_KEY}
  JWT Secret: ${N8N_JWT_SECRET}

EOF
    fi

    cat >> /opt/dockers/configs/credentials.txt <<EOF
================================================================================
ACESSO AOS SERVIÇOS
================================================================================

EOF

    if [ "$INSTALL_N8N" = true ]; then
        if [ "$INSTALL_CADDY" = true ]; then
            cat >> /opt/dockers/configs/credentials.txt <<EOF
n8n:
  URL: https://${DOMAIN}
  IP: https://${SERVER_IP}

EOF
        else
            cat >> /opt/dockers/configs/credentials.txt <<EOF
n8n:
  URL Local: http://localhost:5678
  URL IP: http://${SERVER_IP}:5678

EOF
        fi
    fi

    if [ "$INSTALL_CADDY" = true ]; then
        cat >> /opt/dockers/configs/credentials.txt <<EOF
Certificado SSL:
  Email: ${SSL_EMAIL}
  Domínio: ${DOMAIN}

EOF
    fi

    cat >> /opt/dockers/configs/credentials.txt <<EOF
================================================================================
INFORMAÇÕES DO SISTEMA
================================================================================

Servidor IP: ${SERVER_IP}
Rede Docker: docker-network
Diretório de Dados: /opt/dockers/data/

EOF

    chmod 600 /opt/dockers/configs/credentials.txt
    
    echo -e "${GREEN}✓ Credenciais salvas em /opt/dockers/configs/credentials.txt${NC}"
    echo ""
}

show_summary() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         Instalação Concluída!          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$INSTALL_N8N" = true ]; then
        echo -e "${CYAN}${BOLD}🌐 Acesso aos Serviços:${NC}"
        if [ "$INSTALL_CADDY" = true ]; then
            echo -e "   Domínio:  ${GREEN}https://${DOMAIN}${NC}"
            echo -e "   IP:       ${GREEN}https://${SERVER_IP}${NC}"
        else
            echo -e "   Local:    ${GREEN}http://localhost:5678${NC}"
            echo -e "   Remoto:   ${GREEN}http://${SERVER_IP}:5678${NC}"
        fi
        echo ""
    fi
    
    echo -e "${CYAN}${BOLD}📦 Containers em Execução:${NC}"
    while IFS= read -r line; do
        echo -e "   ${GREEN}✓${NC} $line"
    done < <(docker ps --filter "network=docker-network" --format "{{.Names}}\t{{.Status}}")
    echo ""
    
    if [ "$INSTALL_POSTGRES" = true ] || [ "$INSTALL_N8N" = true ]; then
        echo -e "${CYAN}${BOLD}🔐 Credenciais Salvas:${NC}"
        echo -e "   ${YELLOW}cat /opt/dockers/configs/credentials.txt${NC}"
        echo ""
    fi
    
    echo -e "${CYAN}${BOLD}💡 Comandos Úteis:${NC}"
    echo -e "   ${YELLOW}docker ps${NC}                    - Listar containers"
    echo -e "   ${YELLOW}docker logs -f <nome>${NC}        - Ver logs em tempo real"
    echo -e "   ${YELLOW}docker exec -it <nome> bash${NC}  - Acessar container"
    echo -e "   ${YELLOW}./uninstall.sh${NC}               - Remover tudo"
    echo ""
    
    echo -e "${CYAN}${BOLD}📍 Informações do Servidor:${NC}"
    echo -e "   IP Servidor:  ${GREEN}${SERVER_IP}${NC}"
    echo -e "   Rede Docker:  ${GREEN}docker-network${NC}"
    echo -e "   Dados:        ${GREEN}/opt/dockers/data/${NC}"
    echo ""
}

main() {
    check_root
    select_components
    
    show_header
    echo -e "${GREEN}${BOLD}► Iniciando instalação...${NC}"
    echo ""
    
    if ! check_docker_installed; then
        install_docker
    fi
    
    if [ "$INSTALL_POSTGRES" = true ] || [ "$INSTALL_N8N" = true ] || [ "$INSTALL_CADDY" = true ]; then
        create_network
    fi
    
    if [ "$INSTALL_POSTGRES" = true ] || [ "$INSTALL_N8N" = true ]; then
        get_user_input
    fi
    
    local step=1
    local total_steps=0
    
    [ "$INSTALL_POSTGRES" = true ] && ((total_steps++))
    [ "$INSTALL_N8N" = true ] && ((total_steps++))
    [ "$INSTALL_CADDY" = true ] && ((total_steps++))
    
    if [ "$INSTALL_POSTGRES" = true ]; then
        echo ""
        echo -e "${CYAN}[${step}/${total_steps}] Instalando PostgreSQL...${NC}"
        bash scripts/postgres/install.sh
        ((step++))
    fi
    
    if [ "$INSTALL_N8N" = true ]; then
        echo ""
        echo -e "${CYAN}[${step}/${total_steps}] Instalando n8n...${NC}"
        bash scripts/n8n/install.sh
        ((step++))
    fi
    
    if [ "$INSTALL_CADDY" = true ]; then
        echo ""
        echo -e "${CYAN}[${step}/${total_steps}] Instalando Caddy...${NC}"
        bash scripts/caddy/install.sh
        ((step++))
    fi
    
    show_summary
}

bootstrap_install() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     Instalador Docker Automatizado     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    # Verificar se git está instalado
    if ! command -v git &> /dev/null; then
        echo -e "${CYAN}► Instalando Git...${NC}"
        apt-get update -qq
        apt-get install -y -qq git
        echo -e "${GREEN}  ✓ Git instalado${NC}"
    fi
    
    # Verificar se o diretório já existe
    if [ -d "$INSTALL_DIR/.git" ]; then
        echo -e "${GREEN}✓ Repositório já existe em $INSTALL_DIR${NC}"
    else
        if [ -d "$INSTALL_DIR" ]; then
            echo -e "${YELLOW}⚠  Diretório $INSTALL_DIR já existe (sem git)${NC}"
            rm -rf "$INSTALL_DIR"
        fi
        echo -e "${CYAN}► Clonando repositório...${NC}"
        git clone -q "$REPO_URL" "$INSTALL_DIR"
        echo -e "${GREEN}  ✓ Repositório clonado em $INSTALL_DIR${NC}"
    fi
    
    # Mudar para o diretório de instalação
    cd "$INSTALL_DIR"
    
    # Dar permissão de execução aos scripts
    chmod +x install.sh uninstall.sh scripts/*/install.sh 2>/dev/null || true
    
    echo ""
    echo -e "${CYAN}Iniciando menu de instalação...${NC}"
    echo ""
    
    # Executar o script diretamente do arquivo com flag de bootstrap
    DOCKERS_BOOTSTRAPPED=1 bash "$INSTALL_DIR/install.sh"
    exit $?
}

# Ponto de entrada
if [ "$REMOTE_INSTALL" = true ]; then
    check_root
    bootstrap_install
    # bootstrap_install já executa o script local e faz exit
else
    # Execução local normal
    check_root
    main
fi
