# TECH STACK

## Objetivo

Este documento define oficialmente todas as tecnologias utilizadas no projeto Cria.
Seu objetivo é garantir consistência durante todo o ciclo de desenvolvimento.

---

# Visão Geral

A stack do Cria baseia-se em um modelo híbrido:
Frontend Mobile/Web utilizando Flutter.
Backend as a Service fornecido pelo Supabase (PostgreSQL, Auth e Edge Functions).
Microserviço especializado para extração e processamento de linguagem natural utilizando Python, FastAPI e a API do Google Gemini.

---

# Frontend

## Framework
Flutter

## Linguagem
Dart

## Roteamento
GoRouter

## Bibliotecas Principais
- supabase_flutter (integração DB e Auth)
- google_fonts (tipografia)
- audioplayers / video_player (mídia)

---

# Backend

## Frameworks
FastAPI (Python)
Supabase (Deno para Edge Functions)

## Linguagens
Python 3
TypeScript (Deno)

## Runtime
Deno (Serverless Edge)

## Autenticação
GoTrue (Supabase Auth)

---

# Banco de Dados

## Tecnologia
PostgreSQL (hospedado no Supabase)

## Modelo
Relacional

## Segurança
Row Level Security (RLS) implementado diretamente no Postgres.

---

# Infraestrutura

## Hospedagem
Vercel (Frontend e API Python).
Supabase (Banco de Dados e Edge Functions).

## Serviços Externos
- Google Gemini (API de LLM)
- Mercado Pago (Processamento Pix)

---

# Padrões e Restrições

- O Frontend consome o Supabase diretamente via PostgREST.
- O Frontend consome a API FastAPI apenas para processamento de IA/Scraping.
- Chamadas sensíveis (como checkout Mercado Pago) passam estritamente via Edge Functions (Deno).

---

# Pendências
- TODO: Definições avançadas de monitoramento, logs e CI/CD.
