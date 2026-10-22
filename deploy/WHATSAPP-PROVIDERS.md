# Provedores WhatsApp para Stella

## Decisão técnica: Evolution API como padrão

### Por que não Baileys direto

O stella-agents (fazer.ai) **não usa Baileys diretamente** — usa um microsserviço privado
`baileys-api` da fazer.ai (imagem `ghcr.io/fazer-ai/baileys-api`) que já é uma API REST
sobre Baileys. Ou seja, a "simplicidade" percebida vinha de já haver uma abstração REST.

**Evolution API é exatamente a mesma arquitetura**, mas:
- Open-source (MIT) — sem vendor lock-in com fazer.ai
- API REST pública e bem documentada
- Suporta múltiplos providers (Baileys, Meta Cloud API)
- Comunidade ativa e releases frequentes

### Comparativo de provedores

| Critério | Baileys direto | baileys-api (fazer.ai) | Evolution API | Meta Cloud API |
|---|---|---|---|---|
| Custo | Gratuito | Gratuito (imagem privada) | Gratuito | Por mensagem |
| Dependência vendor | Nenhuma | fazer.ai | Nenhuma | Meta |
| Risco de ban | Alto | Médio | Médio | Nenhum |
| Multi-device | Limitado | Sim | Sim | Sim |
| HSM Templates | Não | Não | Sim | Sim |
| Self-hosted | Sim | Sim | Sim | Parcialmente |
| Complexidade setup | Alta | Média | Baixa | Média |
| Documentação | Código | Interna | Pública | Excelente |

### Estratégia para o produto Stella

**Padrão**: Evolution API (gratuito, self-hosted, documentado)
**Upgrade**: Meta Cloud API para clientes que precisam de HSM ou tolerância zero a ban

Isso dá ao cliente opções claras:
1. **Plano básico**: Evolution API incluso na stack
2. **Plano empresarial**: Meta Cloud API (requer conta Business Verification)

### Arquivos fazer.ai a remover do stella-agents

Para eliminar 100% das referências à fazer.ai no stella-agents:

| Arquivo | Referência | Ação |
|---|---|---|
| `src/config.ts:482` | `FAZER_AI_HUB_URL` | Renomear para `STELLA_HUB_URL` ou remover |
| `src/client/lib/navigation.tsx:194` | Link `app.fazer.ai` | Trocar por URL Sancar |
| `src/client/pages/admin/AdminBrandingPage.tsx` | "fazer.ai identity" | Trocar por "Stella" |
| `src/client/components/ProGate.tsx:29` | Link `app.fazer.ai` | URL Sancar |
| `src/client/components/Sidebar.tsx:138` | Label `fazer.ai` | `sancar.space` |
| `src/client/lib/affiliateLinks.ts` | Links afiliado fazer.ai | Remover |
| `src/api/features/branding/branding.admin.service.ts` | "fazer.ai identity" | "Stella" |
| `src/api/features/updates/updates.controller.ts` | "fazer.ai hub" | "Stella hub" |
