#!/bin/bash
# Stella — Bootstrap de nova instância de cliente
# Uso: ./bootstrap.sh
#
# Pré-requisitos:
#   - Docker + Docker Compose instalados
#   - Arquivo .env preenchido (copie de .env.template)
#   - Nginx ou Traefik configurado para os subdomínios
#   - Certificados SSL válidos (Let's Encrypt ou Cloudflare)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Cores para output ──────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${BLUE}[Stella]${NC} $1"; }
ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# ── Verificações iniciais ──────────────────────────────────────
log "Iniciando bootstrap do Stella..."

[[ -f ".env" ]] || fail "Arquivo .env não encontrado. Copie de .env.template e preencha."

source .env

[[ -z "${POSTGRES_PASSWORD:-}" ]]  && fail "POSTGRES_PASSWORD não definido no .env"
[[ -z "${REDIS_PASSWORD:-}" ]]     && fail "REDIS_PASSWORD não definido no .env"
[[ -z "${SECRET_KEY_BASE:-}" ]]    && fail "SECRET_KEY_BASE não definido no .env"
[[ -z "${N8N_ENCRYPTION_KEY:-}" ]] && fail "N8N_ENCRYPTION_KEY não definido no .env"
[[ -z "${EVOLUTION_API_KEY:-}" ]]  && fail "EVOLUTION_API_KEY não definido no .env"
[[ -z "${CHATWOOT_HOST:-}" ]]      && fail "CHATWOOT_HOST não definido no .env"

ok "Variáveis de ambiente verificadas"

# ── Subir serviços de infraestrutura primeiro ──────────────────
log "Subindo PostgreSQL e Redis..."
docker compose up -d postgres redis

log "Aguardando PostgreSQL ficar pronto..."
until docker compose exec -T postgres pg_isready -U "${POSTGRES_USER:-postgres}" > /dev/null 2>&1; do
  sleep 2
done
ok "PostgreSQL pronto"

until docker compose exec -T redis redis-cli -a "${REDIS_PASSWORD}" ping > /dev/null 2>&1; do
  sleep 2
done
ok "Redis pronto"

# ── Preparar banco do Chatwoot ─────────────────────────────────
log "Preparando banco de dados do Chatwoot..."
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
ok "Banco do Chatwoot preparado"

# ── Subir todos os serviços ────────────────────────────────────
log "Subindo todos os serviços..."
docker compose up -d
ok "Todos os serviços iniciados"

# ── Aguardar Chatwoot ficar disponível ─────────────────────────
log "Aguardando Chatwoot inicializar (pode levar 1-2 minutos)..."
TIMEOUT=120
ELAPSED=0
until curl -sf "http://localhost:${CHATWOOT_PORT:-3000}/auth/sign_in" > /dev/null 2>&1; do
  sleep 5
  ELAPSED=$((ELAPSED + 5))
  [[ $ELAPSED -ge $TIMEOUT ]] && fail "Chatwoot não iniciou em ${TIMEOUT}s. Veja: docker compose logs rails"
done
ok "Chatwoot disponível em https://${CHATWOOT_HOST}"

# ── Resumo ─────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Stella instalado com sucesso!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Chatwoot:     ${BLUE}https://${CHATWOOT_HOST}${NC}"
echo -e "  n8n:          ${BLUE}https://${N8N_HOST}${NC}"
echo -e "  Evolution API:${BLUE}https://${EVOLUTION_HOST}${NC}"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "  1. Acesse o Chatwoot e crie o usuário administrador"
echo "  2. Configure o inbox WhatsApp no Chatwoot via Evolution API"
echo "  3. Importe os templates n8n de: github.com/sancar-space/n8n-templates-para-chatwoot"
echo "  4. Configure os workflows n8n com as credenciais do cliente"
echo ""
