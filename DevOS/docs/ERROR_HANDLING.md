# ERROR HANDLING

## Objetivo

Este documento dita como exceções devem ser tratadas em todo o ecossistema Cria.

---

# LLM e Scraping (Python)

Falhas na extração do HTML (`requests.get`) provocadas por proteções anti-bot em sites externos **não devem causar crash 500**.
A aplicação captura o erro (`except Exception as e_scrape:`) e passa as parciais/metadados (`og:image`) diretamente para o modelo LLM como recurso de fallback. Caso o modelo também falhe na geração do JSON, a aplicação FastAPI retornará um HTTP 500 informando falha clara ao cliente Flutter.

O cliente Flutter sempre exibe alertas amigáveis caso o link colado não possa ser processado ("Não conseguimos processar sua loja automaticamente. Insira os dados.").

# Edge Functions (Deno / MP)

Webhooks de pagamento devem ser **idempotentes**. Se o Mercado Pago notificar um pagamento duas vezes, a segunda notificação (caso não altere um estado além do `received`) deve retornar `200 OK` sem lançar erro interno, não afetando lógicas do banco de dados relacional.

# Flutter UI

Uso ostensivo do `try-catch` em requisições de rede. Mensagens de erro em componentes de notificação ou diálogos informativos, nunca crashes silently.

---

# Pendências
- TODO: Mapeamento completo dos status HTTP de erro de validação (FastAPI pydantic HTTP 422).
