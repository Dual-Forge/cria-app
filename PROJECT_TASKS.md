# PROJECT TASKS

> Este documento representa a lista oficial de trabalho do projeto.
>
> Todas as tarefas aqui descritas derivam do `PROJECT_BRIEF.md` e do escopo MVP atual.

---

## TODO (A Fazer)

- [ ] Validar e implementar tratamento global de timeouts e quedas de conexão no Flutter durante raspagem de IA.
- [ ] Implementar timeout e rollback para itens reservados (`gift_status = 'reserved'`) cujo Pix não foi pago.
- [ ] Mapear mensagens de erro HTTP adequadas para validação do FastAPI.
- [ ] Garantir validação HMAC nas requisições do webhook do Mercado Pago.
- [ ] Ajustar layout da `PublicRegistryScreen` para acessibilidade em navegadores web.
- [ ] Implementar bloqueio ou limite de taxa (Rate Limit) nas consultas da API FastAPI.

---

## EM ANDAMENTO

- [ ] Ajustar integração completa entre Frontend Flutter e a Edge Function de Checkout (`create-checkout-api`).
- [ ] Integrar Webhook do Mercado Pago com o estado atualizado do banco de dados (tabela `gift_contributions` e `items`).
- [ ] Refatoração e aprimoramento de UX nos formulários de entrada de dados do bebê.

---

## CONCLUÍDO (MVP Base)

- [x] Levantar documentação técnica completa do projeto (DevOS Docs).
- [x] Configurar esquema do Banco de Dados no Supabase (tabelas `families`, `baby_profile`, `items`, `gift_contributions`).
- [x] Implementar políticas de Row Level Security (RLS) no PostgreSQL.
- [x] Criar API em Python FastAPI e rota base para análise de links (`/analyze-link`).
- [x] Implementar scraping + extração via LLM (Gemini 2.0 Flash) ignorando parcelamentos e lixos HTML.
- [x] Criar API para dicas geradas por IA (`/get-pregnancy-tips`).
- [x] Criar consultoria para enxoval via Gemini (`/get-advice`).
- [x] Implementar autenticação Supabase Auth no Flutter (`LoginScreen`, `AuthGateScreen`).
- [x] Desenvolver interface de monitoramento e contagem do bebê (BPM, chutes) com `BabyCardWidget`.
- [x] Desenvolver tela pública web de vitrine de presentes (`PublicRegistryScreen`).
- [x] Criar rota e UI para processo de pagamento / checkout de presentes (`WebGiftScreen`).
