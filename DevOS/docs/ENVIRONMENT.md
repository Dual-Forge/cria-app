# ENVIRONMENT

## Objetivo

Este documento lista todas as variáveis de ambiente necessárias para a execução correta do projeto.

---

# Frontend (Flutter)

O arquivo `.env` (ou variáveis equivalentes para o build web) deve conter as chaves públicas:
- `SUPABASE_URL`: A URL do projeto no Supabase.
- `SUPABASE_ANON_KEY`: A chave anônima (pública) para conexão com o BD e Auth.

---

# Backend de IA (Python FastAPI)

O arquivo `.env` do backend requer:
- `GEMINI_API_KEY`: Chave da API do Google Gemini (para acesso ao gemini-2.0-flash).

---

# Edge Functions (Supabase)

Os `secrets` do Supabase precisam estar configurados com:
- `MP_ACCESS_TOKEN`: O token de acesso produtivo ou de testes do Mercado Pago.
- TODO: Listar possíveis tokens ou webhooks secrets exigidos pelo MP para a validação da assinatura no `/mp-webhook`.

---

# Pendências
- TODO: Mapear quaisquer outras chaves necessárias (ex: Sentry para logs se futuramente implementado).
