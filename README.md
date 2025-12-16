# Dockers - Scripts de Automação

Projeto de scripts shell para instalação e configuração automatizada de containers Docker.

## 🚀 Instalação Rápida

Execute um único comando para instalar tudo:

```bash
curl -fsSL https://raw.githubusercontent.com/dalazco/dockers/main/install.sh | sudo bash
```

Ou usando wget:

```bash
wget -qO- https://raw.githubusercontent.com/dalazco/dockers/main/install.sh | sudo bash
```

## 📦 Containers Disponíveis

- **PostgreSQL** - Banco de dados relacional otimizado
- **n8n** - Plataforma de automação de workflows
- **Caddy** (opcional) - Servidor web e reverse proxy com HTTPS automático

## 💡 Como Funciona

1. O script de instalação clona o repositório em `/opt/dockers`
2. Apresenta um menu interativo para você escolher o que instalar
3. Gera automaticamente senhas seguras e tokens
4. Configura tudo com persistência de dados
5. Detecta seu IP público para acesso remoto

## 🎯 Menu Interativo

O instalador apresenta um menu completo onde você escolhe exatamente o que instalar:

**Controles:**
- Digite `1` para marcar/desmarcar PostgreSQL
- Digite `2` para marcar/desmarcar n8n (marca PostgreSQL automaticamente)
- Digite `3` para marcar/desmarcar Caddy
- Digite `A` para selecionar tudo (stack completa)
- Digite `I` para instalar os componentes marcados
- Digite `Q` para sair

**Componentes disponíveis:**
1. PostgreSQL (banco de dados)
2. n8n (automação - requer PostgreSQL)
3. Caddy (reverse proxy com HTTPS - opcional)

**Notas:** 
- Docker será instalado automaticamente se não estiver presente
- Senhas e tokens são gerados automaticamente de forma segura

## 📁 Estrutura do Projeto

```
/opt/dockers/
├── install.sh              # Script de instalação rápida
├── setup.sh                # Menu interativo de configuração
├── uninstall.sh            # Desinstalador completo
├── scripts/
│   ├── postgres/          # Scripts do PostgreSQL
│   ├── n8n/               # Scripts do n8n
│   └── caddy/             # Scripts do Caddy
├── templates/             # Templates de configuração
├── configs/              # Configurações e credenciais geradas
└── data/                 # Dados persistidos dos containers
```

## 🛠️ Uso Manual

Se preferir clonar o repositório manualmente:

```bash
git clone https://github.com/dalazco/dockers.git /opt/dockers
cd /opt/dockers
sudo ./setup.sh
```

## 🔐 Segurança

- Senhas: 25 caracteres alfanuméricos
- Tokens: 128 caracteres alfanuméricos
- Credenciais salvas em `/opt/dockers/configs/credentials.txt` (modo 600)

## 🗑️ Desinstalação

Para remover tudo (containers, imagens, volumes e dados):

```bash
cd /opt/dockers
sudo ./uninstall.sh
```

## 🌐 Acesso aos Serviços

### Sem Caddy (acesso direto):
- n8n: `http://SEU_IP:5678`

### Com Caddy (com HTTPS):
- n8n: `https://seudominio.com`

## 💻 Comandos Úteis

```bash
# Listar containers
docker ps

# Ver logs em tempo real
docker logs -f n8n

# Acessar container
docker exec -it n8n bash

# Ver credenciais
cat /opt/dockers/configs/credentials.txt

# Remover tudo
cd /opt/dockers && sudo ./uninstall.sh
```

## 📍 Informações Técnicas

- **Rede Docker:** `docker-network` (genérica/reutilizável)
- **Dados:** `/opt/dockers/data/` (volumes persistentes)
- **PostgreSQL:** Otimizado para produção, reutilizável
- **n8n:** Configurado com timezone America/Sao_Paulo

## 📝 Licença

MIT
