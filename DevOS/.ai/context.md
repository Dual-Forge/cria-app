# Contexto IA - Cria

## O que o sistema faz?
O Cria é um aplicativo para pais de primeira viagem que engloba ferramentas de saúde gestacional e a criação de uma lista de presentes em forma de vitrine pública. Amigos e parentes doam (via transações Pix integradas ao Mercado Pago) a partir de links de lojas extraídos e organizados usando a inteligência artificial do Google Gemini.

## Stack Técnica
- Frontend: Flutter
- Banco e Auth: Supabase (PostgreSQL)
- Pagamentos e Edge: Supabase Edge Functions (Deno)
- AI e Scraping: Python (FastAPI + Gemini 2.0 Flash)

## Arquitetura Resumida
A UI se comunica com o Supabase nativamente (via SDK e RLS protegendo os dados) para ler perfis e registrar o fluxo da família. Porém, tarefas pesadas de extração (como dicas personalizadas semanais e web scraping de e-commerces) são terceirizadas a um backend isolado em Python que conversa com o Gemini. Webhooks do MP chegam via Deno.

## Estado Atual (MVP)
O MVP contempla Autenticação, Perfis de bebê (BPM e chutes), IA semanal, Scraping de lojas e Checkout (Vitrine + PIX). Futuras versões poderão conter logística de loja proprietária (não incluída hoje).