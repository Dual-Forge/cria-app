# DEVELOPMENT GUIDE

## Objetivo

Este documento funciona como um guia prático para novos desenvolvedores configurarem e iniciarem o ambiente do projeto Cria.

---

# Requisitos do Sistema

- **Flutter SDK** (`>=3.10.1` recomendado)
- **Python 3** (para rodar a API do Gemini local)
- **Supabase CLI** (Opcional, útil para rodar Edge Functions localmente)
- **Deno** (Execução local das funções, instalado automaticamente com Supabase CLI)

---

# Passos para Iniciar

1. Clone o repositório.
2. Inicie o Frontend:
```bash
cd cria_app
flutter pub get
flutter run
```
*(Nota: Certifique-se de configurar as chaves do Supabase no arquivo `.env` primeiro).*

3. Inicie o Backend AI (FastAPI):
```bash
cd cria_backend
pip install -r requirements.txt
python main.py
```
*(Nota: Certifique-se de adicionar sua `GEMINI_API_KEY` no `.env`).*

4. Edge Functions:
O deploy normal é feito pelo Github Actions (TODO: Verificar pipeline) ou via CLI.
```bash
cd cria_app
supabase functions serve
```

---

# Dicas Úteis

- A API FastAPI escuta em `http://localhost:8000` por padrão.
- Ao testar extração de links via web scraper (`analyze-link`), links que possuírem proteções de proxy muito fortes (ex: Amazon) podem precisar de testes extras simulando o User-Agent ou falhar graciosamente, confiando exclusivamente no fallback do Gemini.

---

# Pendências
- TODO: Inserir tutoriais exatos de deploy em produção (Vercel e Supabase Dashboard).
