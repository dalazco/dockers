# Dockers - Scripts de Automação

Projeto de scripts shell para instalação e configuração automatizada de containers Docker.

## 🚀 Containers Disponíveis

- **n8n** - Plataforma de automação de workflows
- **PostgreSQL** - Banco de dados (usado pelo n8n)
- **Caddy** (opcional) - Servidor web e reverse proxy com HTTPS automático

## 📋 Pré-requisitos

- Ubuntu/Debian Linux
- Acesso root ou sudo
- Conexão com internet

## 🔧 Instalação

```bash
# Clone o repositório
git clone https://github.com/dalazco/dockers.git
cd dockers

# Execute o script de instalação (como root)
sudo ./install.sh
```

### Menu Interativo

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
dockers/
├── install.sh              # Script principal de instalação
├── scripts/
│   ├── n8n/               # Scripts do n8n
│   ├── postgres/          # Scripts do PostgreSQL
│   └── caddy/             # Scripts do Caddy
├── templates/             # Templates de configuração
└── configs/              # Configurações geradas
```

## 🛠️ Uso

O script de instalação irá:
1. Verificar e instalar Docker se necessário
2. Criar rede Docker para comunicação entre containers
3. Configurar PostgreSQL com banco de dados para n8n
4. Instalar e configurar n8n
5. Configurar Caddy como reverse proxy

## 📝 Licença

MIT
