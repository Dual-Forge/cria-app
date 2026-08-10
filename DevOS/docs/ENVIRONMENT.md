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
- `GROQ_API_KEY`: Chave da API Groq, usada pela Edge Function `ai-proxy` (a IA agora roda via proxy autenticado; a chave nunca é embarcada no app).
- `SUPABASE_URL`: URL do projeto (usado pela `ai-proxy` ao compor endpoints, quando necessário).

> Nota: a integração com Mercado Pago (PIX/checkout) foi **removida** do produto.

---

# Pendências
- TODO: Mapear quaisquer outras chaves necessárias (ex: Sentry para logs se futuramente implementado).
