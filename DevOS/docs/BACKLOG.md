# BACKLOG

## Objetivo

Este documento contém todas as funcionalidades, ideias e melhorias que não fazem parte do escopo atual (MVP) do Cria.

---

# Melhorias Técnicas

## Otimização de Backend
- Tratamentos de erro granulares no frontend para falhas da IA e raspagem de lojas.
- Validação do comportamento caso a chave PIX da família não esteja configurada no momento do presente.
- Limitação de Rate Limit (limites de chamadas da API do Gemini e limites no Supabase).

## Segurança / Prevenção a Falhas
- Estratégia de fallback para falha de extração do HTML por bloqueios (anti-bot) via `requests` Python (exemplo: usar headers dinâmicos ou inserir manualmente).
- Solução para o "timeout" do Mercado Pago (usar WebSockets ou polling para atualizar status em tempo real).

---

# Novas Funcionalidades (Fora do Escopo Atual)

- **E-commerce Próprio:** Gerenciar estoque e vender produtos de forma nativa.
- **Logística e Envio:** Integração com transportadoras para envio direto dos presentes.
- **Novas Integrações de Pagamento:** Além de Pix, suportar cartão de crédito e boleto.
- **TODO:** Definir demais funcionalidades de negócio futuras listadas pelos stakeholders.
