# SECURITY

## Objetivo

Este documento aborda regras de segurança, políticas e proteção de dados do Cria.

---

# Autenticação

A autenticação principal ocorre via **Supabase Auth** no Frontend. Não é permitido salvar JWTs manualmente ou contornar as sessões GoTrue da biblioteca oficial `supabase_flutter`.

# Autorização e Dados (RLS)

- **Proteção Base**: O PostgreSQL hospeda regras rígidas de **Row Level Security (RLS)**.
- Os perfis, métricas do bebê (`baby_profile`) e doações (`gift_contributions`) têm suas tabelas atreladas à verificação da função `auth.uid()`, filtrando apenas para dados referentes à `family_id` ao qual o usuário pertence.
- A tabela `items` que serve a vitrine tem acesso público SELECT permitido **se, e somente se,** o status e flag `is_gift = true` existirem, isolando potenciais vazamentos de dados da família.

# Pagamentos e Edge

A transação de um presente (gerar cobrança Pix Mercado Pago) não é feita a partir do cliente Flutter, pois isso exporia as chaves secretas (Access Tokens) no binário do app. Toda chamada vai pela rota da **Supabase Edge Function** (`/create-checkout-api`), que acessa o segredo seguramente e se comunica com o MP.

O status de pagamento é atualizado internamente via webhooks em `/mp-webhook`, que validam a integridade antes de marcar o presente como `received` (TODO: Confirmar as assinaturas de Webhook).

---

# Logs

Informações sensíveis de usuários (Pix Key, CPF se houver) não devem ser transcritas em logs do Python backend sob nenhuma circunstância.

---

# Pendências
- TODO: Confirmar o sistema de verificação HMAC/Signature do Webhook do Mercado Pago no Deno.
