# ARCHITECTURE

## Objetivo

Este documento descreve toda a arquitetura do sistema Cria.

---

# Arquitetura Geral

Client-Server com Backend as a Service (BaaS) e Microserviço Auxiliar.

O aplicativo central é desenvolvido em Flutter e consome serviços diretamente do Supabase. Operações que requerem Inteligência Artificial e processamento HTML pesado são delegadas a um backend independente em Python. Processamento de transações e webhooks externos passam por Edge Functions.

---

# Estrutura do Projeto

- `cria_app/`: Frontend Flutter organizado em features.
- `cria_backend/`: Microserviço FastAPI para IA.
- `database/`: Scripts de inicialização.
- `supabase/`: Migrations e Edge Functions (Deno).

---

# Camadas e Comunicação

### Frontend (Flutter)
- Responsável pela UI, gerenciamento de estado e experiência. Comunica-se diretamente com o Supabase Auth e DB para leitura/escrita relacional. Chama o FastAPI para NLP. Chama Deno Edge para gerar Pix.

### BaaS Core (Supabase PostgreSQL + GoTrue)
- Fonte da verdade de dados e perfis. Protegido via Row Level Security.

### Edge (Supabase Functions em Deno)
- Processa pagamentos via Mercado Pago, isolando chaves de API secretas do frontend.

### Microserviço IA (FastAPI)
- Responsável apenas pelo scraping, parser com BeautifulSoup, e orquestração de chamadas ao Gemini.

---

# Módulos Principais

- **Autenticação / Pais (`features/parents`)**: Fluxo de entrada, gerenciado via Supabase Auth.
- **Bebê (`features/baby`)**: Monitoramento de indicadores (BPM, chutes). Acesso focado no perfil da criança.
- **Especialista IA (`features/ai_specialist`)**: Assistente focado em contexto de maternidade consumindo backend Python.
- **Lista de Presentes (`features/store_scraping`)**: Módulo de scraping via IA e checkout de contribuições.

---

# Segurança

- O RLS (Row Level Security) garante que os pais apenas visualizem/editem recursos (`baby_profile`, `gift_contributions`) associados ao seu `family_id`.
- Rotas públicas de vitrine acessam dados limitados devido à política de SELECT exclusiva para itens marcados como presentes (`is_gift = true`).
- Transações do Mercado Pago não podem ser geradas/alteradas pelo front-end sem passar pelo webhook em servidor protegido.
