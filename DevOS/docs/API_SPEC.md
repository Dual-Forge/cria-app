# API SPECIFICATION

## Objetivo

Este documento define todos os contratos da API do sistema Cria (Python FastAPI + Supabase Edge Functions).

---

# Informações Gerais

## Arquitetura
REST (Python FastAPI e Deno Edge Functions).

## Base URL
- FastAPI: `http://localhost:8000` (desenvolvimento) / TODO (produção)
- Edge Functions: `https://[SUPABASE_PROJECT].supabase.co/functions/v1/`

## Autenticação
FastAPI: Sem autenticação mandatória no momento (TODO).
Edge Functions: JWT e verificação de assinatura (Mercado Pago).

---

# Endpoints (FastAPI)

## Dicas de Gravidez Semanais
### Objetivo
Gerar conselhos gerados por IA para a mãe.
### Método HTTP
`POST`
### URL
`/get-pregnancy-tips`
### Body
```json
{
  "week": 12,
  "diary_context": "Sinto muitos enjoos matinais."
}
```
### Exemplo de Resposta
```json
{
  "diet": "Tome chás claros e coma biscoitos secos.",
  "exercise": "Faça caminhadas leves.",
  "mental": "Respire fundo e tenha paciência.",
  "baby_focus": "O bebê está do tamanho de um limão."
}
```

## Analisador de Links de Compra
### Objetivo
Extrair imagem, nome curto e preço à vista via web scraping auxiliado por IA.
### Método HTTP
`POST`
### URL
`/analyze-link`
### Body
```json
{
  "url": "https://loja.exemplo.com/produto"
}
```
### Exemplo de Resposta
```json
{
  "name": "Fralda Pampers M",
  "price": 139.90,
  "image_url": "https://img.exemplo.com/123.jpg"
}
```

## Consultor de Enxoval
### Objetivo
Dica de compra via IA.
### Método HTTP
`POST`
### URL
`/get-advice`
### Body
```json
{
  "item_name": "Fralda",
  "age_range": "0-3"
}
```
### Exemplo de Resposta
```json
{
  "advice": "Para essa fase, você vai precisar de muitas fraldas P..."
}
```

---

# Endpoints (Edge Functions / Supabase)

## Checkout
### Objetivo
Gerar requisição Pix no Mercado Pago.
### Método HTTP
`POST`
### URL
`/create-checkout-api`

## Webhook Mercado Pago
### Objetivo
Receber atualização de pagamento.
### Método HTTP
`POST`
### URL
`/mp-webhook`

---

# Pendências
- TODO: Adicionar documentação dos Payloads detalhados das Edge Functions de Checkout e Webhook.
