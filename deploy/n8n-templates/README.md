# Templates n8n — Stella (Sancar)

Biblioteca de workflows n8n para o stack de atendimento com IA da Sancar.

Adaptados da "Secretária v3" (fazer.ai/Lucas Moreira) com identidade Sancar, modelo DeepSeek e lógica de transbordo por atribuição.

---

## Pré-requisitos

### Nodes da comunidade (instalar antes de importar)

No n8n: **Settings → Community Nodes → Install**

```
@devlikeapro/n8n-nodes-chatwoot
@elevenlabs/n8n-nodes-elevenlabs
```

### Variáveis de ambiente obrigatórias no n8n

Configure em **Settings → Variables** (ou via env do container):

| Variável | Descrição |
|---|---|
| `CHATWOOT_URL` | URL do Chatwoot (ex: `https://chat.stella.sancar.space`) |
| `CHATWOOT_TOKEN` | Access Token da conta (Settings → Access Token) |
| `CHATWOOT_ACCOUNT_ID` | ID da conta no Chatwoot |
| `DEEPSEEK_API_KEY` | Chave da API DeepSeek |
| `GROQ_API_KEY` | Chave Groq (transcrição de áudio via Whisper) |
| `ELEVENLABS_API_KEY` | Chave ElevenLabs (resposta em voz — opcional) |
| `ELEVENLABS_VOICE_ID` | ID da voz ElevenLabs (opcional) |
| `GOOGLE_CALENDAR_ID` | ID do calendário Google (agendamento — opcional) |
| `ASAAS_API_KEY` | Chave Asaas (cobranças PIX — opcional) |

### Credenciais n8n (criar em Credentials)

- **DeepSeek**: tipo "OpenAI API" — Base URL: `https://api.deepseek.com/v1`, API Key: `DEEPSEEK_API_KEY`
- **Chatwoot**: tipo "Header Auth" — Header: `api_access_token`, Value: `CHATWOOT_TOKEN`
- **PostgreSQL**: apontar para o mesmo banco do Chatwoot (schema `n8n`)
- **Google OAuth2**: necessário para Calendar e Drive
- **ElevenLabs**: chave da API (se usar voz)
- **Asaas**: chave da API (se usar cobranças)

---

## Ordem de importação

Importe nessa ordem — o workflow `00` cria as tabelas e configurações que os demais usam:

| Arquivo | Descrição |
|---|---|
| `00-configuracoes-stella.json` | **Executar primeiro** — cria tabelas PostgreSQL, labels e atributos no Chatwoot |
| `01-stella-atendimento-ia.json` | Agente principal de IA (webhook de entrada + LLM DeepSeek) |
| `07-quebrar-enviar-mensagens.json` | Envio humanizado de mensagens longas |
| `07.1-baileys-quebrar-enviar-mensagens.json` | Variante para Baileys API (WhatsApp nativo) |
| `05-transbordo-humano.json` | Transbordo: atribui conversa a atendente humano |
| `05.1-transbordo-humano-multi-alerta.json` | Transbordo com múltiplos alertas |
| `02-enviar-arquivo-gdrive.json` | Envio de arquivos do Google Drive |
| `03-buscar-janelas-calendar.json` | Consulta disponibilidade no Google Calendar |
| `04-criar-evento-calendar.json` | Criação de eventos no Google Calendar |
| `04.1-atualizar-agendamento.json` | Atualização de agendamentos |
| `09-cancelar-agendamento.json` | Cancelamento de agendamentos |
| `11-lembretes-agendamento.json` | Envio de lembretes de agendamento |
| `06-integracao-asaas.json` | Cobranças e PIX via Asaas |
| `08-agente-assistente-interno.json` | Assistente para atendentes humanos (uso interno) |
| `10-buscar-criar-contato-conversa.json` | Utilitário: busca ou cria contato/conversa |
| `12-gestao-ligacoes.json` | Gestão de chamadas (ElevenLabs + Twilio) |
| `13-recuperacao-leads.json` | Follow-up automático para leads frios |

---

## Configuração inicial (`00-configuracoes-stella.json`)

Ao executar o workflow `00`, ele cria automaticamente:

### Tabelas PostgreSQL (schema `n8n`)
- `n8n_historico_mensagens` — histórico de conversas para memória do agente
- `n8n_fila_mensagens` — fila de envio humanizado de mensagens
- `n8n_status_atendimento` — estado atual de cada conversa

### Labels no Chatwoot
- `testando-stella` — conversa em modo de teste (agente não responde clientes reais)
- `atendimento-humano` — conversa sob responsabilidade de humano

### Atributos de conversa
- `id_agente_humano` — ID do atendente Chatwoot a receber transbordo
- `prompt_personalizado` — instrução adicional por conversa

---

## Transbordo humano

O workflow `05-transbordo-humano.json` usa a **API de atribuição do Chatwoot** (não etiquetas):

```
POST /api/v1/accounts/{id}/conversations/{id}/assignments
Body: { "assignee_id": <id_do_agente> }
```

Quando uma conversa é atribuída a um atendente humano, o agente de IA para de responder automaticamente. Para reativar a IA, remova a atribuição ou configure via atributo de conversa.

---

## Modelo de IA

O agente principal (`01`) usa **DeepSeek Chat** por padrão:
- Endpoint: `https://api.deepseek.com/v1` (compatível com OpenAI)
- Modelo: `deepseek-chat`

Para trocar o modelo, edite o node "Chamar IA (DeepSeek)" no workflow `01`.

---

## Checklist de deploy

- [ ] Stack Chatwoot + n8n rodando (ver `docker-compose.coolify-staging.yml`)
- [ ] Nodes da comunidade instalados no n8n
- [ ] Credenciais configuradas no n8n
- [ ] Variáveis de ambiente preenchidas
- [ ] Workflow `00` importado e executado (cria tabelas e labels)
- [ ] Webhook do workflow `01` copiado e configurado no Chatwoot (Settings → Integrations → Agent Bots)
- [ ] Webhook do workflow `07` configurado no `01` para envio humanizado
- [ ] Webhook do workflow `05` configurado para transbordo

---

## Canais suportados

- **WhatsApp** via Baileys API (nativo no fork fazer.ai/chatwoot)
- **Web Widget** (chat no site)
- **Instagram DM**, **Facebook Messenger** (via Chatwoot)
- **E-mail** (via Chatwoot)
