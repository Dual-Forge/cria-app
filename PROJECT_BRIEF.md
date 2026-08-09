# PROJECT BRIEF

> Este documento é a fonte oficial de verdade do projeto.
> Toda a documentação, implementação e decisões técnicas deverão ser derivadas deste documento.
> Nenhuma funcionalidade deve ser implementada sem estar descrita ou aprovada neste documento.

---

# 1. Visão Geral

## Nome do Projeto
Cria

## Descrição
O Cria é um aplicativo voltado para famílias e pais de primeira viagem, que oferece acompanhamento gestacional (como dicas e contagem de chutes/BPM) e uma vitrine pública de presentes (lista de enxoval) onde amigos e familiares podem contribuir financeiramente.

## Problema
Gestantes e pais de primeira viagem precisam de um acompanhamento simplificado de informações do bebê e de uma maneira fácil de organizar listas de presentes e receber contribuições de forma centralizada e sem fricção para quem presenteia.

## Solução
O aplicativo centraliza o acompanhamento do bebê com ferramentas integradas e dicas baseadas em inteligência artificial. Também oferece uma funcionalidade de vitrine pública de presentes integrada com pagamentos via Pix (Mercado Pago), onde é possível raspar dados de e-commerces e criar a lista automaticamente.

## Objetivos
- Facilitar o acompanhamento do desenvolvimento do bebê.
- Fornecer dicas personalizadas usando IA.
- Simplificar a criação de listas de enxoval através de web scraping.
- Processar pagamentos de presentes (contribuições) de forma transparente.

---

# 2. Escopo

## MVP
- Autenticação de pais.
- Cadastro de perfis de famílias e bebês.
- Acompanhamento do bebê (frequência cardíaca, contagem de chutes).
- Integração com IA para geração de dicas semanais de gravidez e consultoria de enxoval.
- Criação de lista de presentes com extração automatizada de dados de links (web scraping via IA).
- Vitrine pública para visualização dos presentes por terceiros.
- Checkout e pagamento de contribuições via integração com Mercado Pago (Pix).

## Fora do Escopo
- TODO: Definir escopo não coberto na versão atual (ex: e-commerce próprio, envio de produtos físicos, etc).

## Futuras Expansões
- TODO: Levantar futuras expansões junto aos stakeholders.

---

# 3. Usuários

## Tipos de Usuários

### Pais / Família
- **Objetivo**: Acompanhar a gestação e gerenciar a lista de presentes.
- **Permissões**: Ler, criar e editar perfil do bebê, itens da lista de presentes.
- **Responsabilidades**: Configurar chave Pix, adicionar itens na lista, marcar contribuições como agradecidas.

### Presenteadores (Público/Anônimo)
- **Objetivo**: Visualizar a lista e realizar contribuições financeiras.
- **Permissões**: Acesso de leitura à vitrine pública e criação de intenções de contribuição.
- **Responsabilidades**: Preencher dados de checkout e realizar o pagamento via Pix.

---

# 4. Funcionalidades

## Módulos do Sistema

### 1. Autenticação e Pais (`features/parents`)
- **Objetivo**: Gerenciar o acesso dos pais ao app.
- **Funcionalidades**: Login, cadastro, fluxo principal.
- **Fluxo principal**: SplashScreen -> Login -> Home.

### 2. Bebê (`features/baby`)
- **Objetivo**: Acompanhar métricas e dados do bebê.
- **Funcionalidades**: Detalhes do bebê, perfil, contagem de chutes, registro de BPM, timeline.
- **Dependências**: Tabela `baby_profile`.

### 3. Especialista IA (`features/ai_specialist`)
- **Objetivo**: Fornecer dicas baseadas no tempo de gestação.
- **Funcionalidades**: Dicas semanais de saúde, dieta e consultoria de itens de enxoval.
- **Dependências**: API Python Backend (Gemini 2.0 Flash).

### 4. Lista de Presentes e Scraping (`features/store_scraping`)
- **Objetivo**: Criação de lista e recebimento de presentes.
- **Funcionalidades**: Raspar URLs de lojas para extrair preços/imagens, exibição de vitrine pública, fluxo de checkout (Pix).
- **Dependências**: API Python Backend para web scraping, Edge Functions no Supabase (Mercado Pago).

---

# 5. Fluxos do Sistema

- **Cadastro/Login**: Usuário se autentica via Supabase Auth.
- **Acompanhamento Gestacional**: Usuário acessa detalhes do bebê, insere BPM e contagem de chutes.
- **Adição de Presente**: Usuário cola o link de um produto -> Backend Python raspa a página + analisa com Gemini -> Produto é salvo na lista.
- **Compra de Presente (Checkout)**: Visitante acessa rota pública `/presentes/:id` -> Escolhe o presente -> Informa nome e mensagem -> Gera Pix (Mercado Pago via Edge Function) -> Efetua pagamento -> Status do presente é atualizado.

---

# 6. Regras de Negócio

- **Limites de BPM**: O BPM registrado do bebê deve estar entre 40 e 200.
- **Unicidade de Perfil**: Cada família pode ter apenas um perfil de bebê (`UNIQUE(family_id)`).
- **Tratamento de Preços**: A extração de preços via IA deve ignorar parcelamentos e buscar sempre o preço à vista.
- **Status do Presente**: Um item tem os estados: 'available', 'reserved' ou 'received'.

---

# 7. Modelo de Dados

### `families`
- **Objetivo**: Agrupar usuários (pais) e informações de recebimento.
- **Principais atributos**: `id`, `pix_key`.

### `baby_profile`
- **Objetivo**: Dados gestacionais.
- **Principais atributos**: `family_id`, `profile_photo_url`, `last_bpm`, `kick_count`, `expected_due_date`.
- **Relacionamentos**: Pertence a `families`.

### `items`
- **Objetivo**: Registro de presentes.
- **Principais atributos**: `id`, `is_gift`, `gift_status`.

### `gift_contributions`
- **Objetivo**: Registrar transações de presentes recebidos.
- **Principais atributos**: `family_id`, `item_id`, `giver_name`, `giver_nickname`, `message_to_parents`, `thanked`.
- **Relacionamentos**: Pertence a `families` e `items`.

---

# 8. Tecnologias

- **Frontend**: Flutter (Dart) com suporte a Web (GoRouter).
- **Backend (Dados/Auth)**: Supabase (PostgreSQL, GoTrue).
- **Backend (IA/Scraping)**: Python 3 com FastAPI.
- **IA**: Google Gemini (gemini-2.0-flash).
- **Serverless/Edge**: Supabase Edge Functions (Deno) para webhooks e integração com Mercado Pago.
- **Banco de Dados**: PostgreSQL (via Supabase).
- **Hospedagem**: Vercel (Front/Python App), Supabase (DB/Functions).
- **Integrações/Serviços Externos**: Mercado Pago (Pagamentos via Pix).

---

# 9. Arquitetura

- **Arquitetura Geral**: Client-Server com Backend as a Service (Supabase) + Microserviço Auxiliar (Python API).
- **Frontend Flutter**: Orientado a features (`lib/features/`). Gerenciamento de estado misto/Provider, rotas via `go_router`.
- **Comunicação**: O Flutter consome o Supabase diretamente para dados relacionais (PostgREST) e autenticação. Consome a API Python (FastAPI) para análise de links e geração de conteúdo via LLM. As Edge Functions mediam as chamadas sensíveis de pagamento (Mercado Pago).

---

# 10. Interface

- **Estilo Visual**: Tema limpo e focado em maternidade.
- **Paleta**: Tema baseado em tons roxos (`Colors.purple`, `Colors.pink`).
- **Tipografia**: Google Fonts (Nunito para textos gerais, Quicksand para títulos).
- **Responsividade**: Aplicativo Mobile primário, mas com vitrine de presentes acessível via Web (GoRouter).

---

# 11. Segurança

- **Autenticação**: Gerenciada pelo Supabase Auth.
- **Autorização (Banco)**: Implementado Row Level Security (RLS) no PostgreSQL. Pais só acessam os perfis e dados de sua própria família.
- **Rotas Públicas**: Políticas específicas (RLS) liberam `SELECT` para a tabela de `items` quando `is_gift = true`.
- **Integração MP**: Webhooks validados dentro das Edge Functions em Deno, isolando chaves de API.

---

# 12. Requisitos Não Funcionais

- **Performance**: Raspagem de dados deve utilizar timeout de 10s para evitar travamentos na experiência.
- **Disponibilidade**: Uso de serviços serverless (Vercel, Supabase) para garantir alto uptime.
- **Manutenibilidade**: Código organizado por features; uso de análise estática e linting no Flutter.

---

# 13. Integrações

### Mercado Pago
- **Objetivo**: Processar pagamentos Pix de presentes.
- **Tecnologia**: Supabase Edge Functions / Deno.
- **Fluxo**: Criação do checkout via `/create-checkout-api` e recebimento de atualização via webhook em `/mp-webhook`.

### Google Gemini API
- **Objetivo**: Processamento de linguagem natural, extração de dados de HTML e dicas.
- **Tecnologia**: Python / GenAI SDK.
- **Fluxo**: Recebe o payload do Flutter, processa o prompt com LLM, retorna JSON estruturado.

---

# 14. Restrições

- **Técnicas**: A raspagem de e-commerces está sujeita a bloqueios (anti-bot) por parte das lojas, havendo falhas que dependem da compreensão do Gemini para extrair informações do HTML parcialmente raspado.
- **TODO**: Levantar limitações de limites (rate limit) no plano do Gemini API e Supabase.

---

# 15. Decisões do Projeto

- **Separação de Backend**: Utilização de um microserviço em Python isolado do Supabase para processamento de IA.
  - *Justificativa*: Facilidade e ecossistema maduro em Python para uso de LLMs e BeautifulSoup.
- **Scraping via LLM**: Em vez de fazer parsers manuais para cada loja, a IA interpreta o HTML genérico.
  - *Justificativa*: Reduz manutenção de scripts de scraping devido a mudanças constantes no frontend das lojas.

---

# 16. Riscos

- **Falha de Extração (Scraping)**: Mudanças nos anti-bots (Cloudflare, etc) das grandes lojas impedirem o `requests` do Python.
  - *Probabilidade*: Média/Alta.
  - *Mitigação*: Solicitar que o usuário insira manualmente os dados se a raspagem falhar ou usar headers avançados.
- **Timeout na Criação do PIX**: O webhook do Mercado Pago pode demorar a confirmar.
  - *Mitigação*: Pooling ou WebSockets/Realtime do Supabase na tela do cliente.

---

# 17. Critérios de Sucesso

- Pais conseguem criar uma conta, inserir dados do bebê e receber dicas.
- Pais conseguem adicionar links de produtos e o sistema extrai o preço/nome corretamente.
- Amigos/familiares conseguem acessar a URL pública, gerar o Pix e concluir a contribuição, atualizando o status no app.

---

# 18. Pendências

- TODO: Confirmar tratamentos de erro exatos no frontend quando o backend de IA (FastAPI) retornar erro ou falhar ao raspar a loja.
- TODO: Validar comportamento caso a chave PIX da família não esteja cadastrada e alguém tente presentear.

---

# 19. Glossário

- **BPM**: Batimentos Por Minuto (Frequência cardíaca fetal).
- **RLS**: Row Level Security (Segurança a nível de linha no Supabase).
- **Edge Function**: Funções Serverless rodando próximas ao usuário, usadas para segurança (pagamentos).

---

# 20. Resumo Executivo

O projeto **Cria** é um aplicativo mobile/web (desenvolvido em Flutter) focado em pais de primeira viagem. Ele mescla utilitários de acompanhamento gestacional (chutes, batimentos e dicas geradas por IA) com uma plataforma de criação de listas de enxoval. O principal diferencial técnico é o uso da IA (Google Gemini via um serviço backend FastAPI/Python) para raspar e estruturar dados de qualquer link de loja e uma infraestrutura moderna (Supabase) que gerencia autenticação, banco de dados (com Row Level Security) e processos críticos de pagamento via integrações (Pix do Mercado Pago usando Edge Functions).
