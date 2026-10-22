# Stella — Deploy Template

Stack completa para nova instância de cliente Stella:
- **Chatwoot** v4.18.0 — CRM de atendimento
- **n8n** — Automação e agente de IA
- **Evolution API** v2.2.3 — Provedor WhatsApp (REST sobre Baileys)
- **PostgreSQL** 16 com pgvector — Banco de dados
- **Redis** 7 — Cache e filas

## Pré-requisitos

- Docker Engine 24+ e Docker Compose v2
- Nginx ou Traefik para proxy reverso com SSL
- 3 subdomínios com SSL (Chatwoot, n8n, Evolution API)
- Mínimo: 4 vCPU, 8 GB RAM, 50 GB SSD

## Instalação rápida

```bash
# 1. Copiar e preencher variáveis
cp .env.template .env
nano .env

# 2. Executar bootstrap
chmod +x bootstrap.sh
./bootstrap.sh
```

## Estrutura

```
deploy/
├── docker-compose.yml   # Stack completa
├── .env.template        # Variáveis de ambiente (copiar para .env)
├── init-db.sql          # Cria bancos n8n e evolution no PostgreSQL
├── bootstrap.sh         # Script de instalação automatizada
└── README.md            # Este arquivo
```

## Variáveis obrigatórias

| Variável | Descrição |
|---|---|
| `CHATWOOT_HOST` | Subdomínio do Chatwoot (ex: `chat.cliente.com.br`) |
| `N8N_HOST` | Subdomínio do n8n |
| `EVOLUTION_HOST` | Subdomínio do Evolution API |
| `POSTGRES_PASSWORD` | Senha do PostgreSQL (mín. 32 chars) |
| `REDIS_PASSWORD` | Senha do Redis (mín. 32 chars) |
| `SECRET_KEY_BASE` | Chave Rails — `openssl rand -hex 64` |
| `N8N_ENCRYPTION_KEY` | Chave n8n — `openssl rand -hex 32` |
| `EVOLUTION_API_KEY` | Chave Evolution API — `openssl rand -hex 32` |

## Conectar WhatsApp

Após subir a stack, conecte um número WhatsApp via Evolution API:

```bash
# Criar instância
curl -X POST https://${EVOLUTION_HOST}/instance/create \
  -H "apikey: ${EVOLUTION_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "cliente-01", "qrcode": true}'

# Ler QR Code
curl https://${EVOLUTION_HOST}/instance/connect/cliente-01 \
  -H "apikey: ${EVOLUTION_API_KEY}"
```

## Importar templates n8n

Após subir o n8n, importe os workflows de atendimento:
→ [github.com/sancar-space/n8n-templates-para-chatwoot](https://github.com/sancar-space/n8n-templates-para-chatwoot)

## Manutenção

```bash
# Ver logs
docker compose logs -f rails
docker compose logs -f n8n

# Parar tudo
docker compose down

# Atualizar Chatwoot
docker compose pull rails sidekiq
docker compose up -d rails sidekiq
docker compose exec rails bundle exec rails db:migrate
```
