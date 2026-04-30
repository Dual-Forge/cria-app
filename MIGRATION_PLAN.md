# MIGRATION PLAN — Flutter → React Native

> Gerado em 2026-04-05 | App: Cria (cria_app)

---

## 1. TELAS EXISTENTES

### Fluxo de Autenticação
| Tela | Arquivo | Descrição |
|------|---------|-----------|
| Login / Registro | `screens/login_screen.dart` | Email/senha + Google OAuth via Supabase. UI com GlassCard, gradientes, animações |
| Auth Gate | `screens/auth_flow_screens.dart` | StreamBuilder que redireciona para Login, ProfileSetup ou MainScreen conforme estado auth |
| Setup de Perfil | `screens/profile_setup_screen.dart` | Primeiro acesso: nome, apelido, role (mae/pai), foto, código de família, sangue, nascimento |

### Navegação Principal (Bottom Nav — 5 abas)
| Tela | Arquivo | Descrição |
|------|---------|-----------|
| Main (Shell) | `screens/main_screen.dart` | IndexedStack com 5 abas + stream em tempo real da família para themeColor |
| Gravidez (Aba 1) | `screens/home_screen.dart` (`HomePregnancyScreen`) | Visão geral da gestação (semana, fruta, peso) + insights IA + Agenda médica com calendário |
| Enxoval (Aba 2) | `screens/shopping_list_screen.dart` (`ShoppingListScreen` + `CategoryDetailScreen`) | Lista de enxoval com categorias, filtros por faixa etária, progresso financeiro, gráfico por categoria, web scraping de links |
| Diário (Aba 3) | `screens/diary_screen.dart` | Registro de humor, peso, notas e fotos. Estilo chat bubble |
| Presentes (Aba 4) | `screens/gifts_management_screen.dart` | Mural de presentes recebidos, progresso de agradecimento (2 pessoas), botão WhatsApp |
| Ajustes (Aba 5) | `screens/settings_screen.dart` | Edição de perfil, dados do bebê, DUM, link público, código de convite, logout |

### Telas Secundárias
| Tela | Arquivo | Descrição |
|------|---------|-----------|
| Cadastro do Bebê | `screens/baby_registration_screen.dart` | Nome e sexo do bebê (define tema do app) |
| Chatbot AI | `screens/chatbot_screen.dart` | Chat com Gemini 2.5 Flash, histórico salvo no Supabase, disclaimer médico |
| Pagamento PIX | `screens/pix_payment_screen.dart` | Exibe QR Code Pix, countdown 10min, polling a cada 3s |
| Confirmação (Pós-pagamento) | `screens/confirmation_screen.dart` | Tela de "Pagamento Aprovado" |
| Checkout Web | `screens/web_gift_screen.dart` | Formulário do padrinho (nome, email, telefone, mensagem) → gera PIX |
| Vitrine Pública Presentes | `screens/public_registry_screen.dart` | Grid de presentes disponíveis para visitantes (rota `/presentes/:id`) |

---

## 2. TABELAS SUPABASE

### Tabelas de Dados

| Tabela | Campos identificados | Usada em |
|--------|---------------------|----------|
| **`profiles`** | `id`, `full_name`, `nickname`, `role` ('mae'/'pai'), `birth_date`, `blood_type`, `photo_url`, `address`, `phone`, `dum_date`, `family_id`, `created_at` | Auth, ProfileSetup, Home, Chatbot, Settings |
| **`families`** | `id`, `baby_name`, `baby_gender` ('menino'/'menina'/'neutro'), `invite_code`, `created_by`, `dum_date` | Main, Home, Settings, ProfileSetup, BabyRegistration |
| **`items`** | `id`, `name`, `category`, `price`, `notes`, `link_url`, `image_url`, `age_range`, `is_purchased`, `is_gift`, `family_id`, `user_id`, `created_at`, `gift_status` ('received'), `qty` | ShoppingList, CategoryDetail, PublicRegistry, mp-webhook |
| **`diary_entries`** | `id`, `user_id`, `entry_date`, `mood`, `notes`, `weight`, `photo_url` | DiaryScreen |
| **`chat_messages`** | `id`, `user_id`, `family_id`, `role` ('user'/'model'), `content`, `created_at` | ChatbotScreen, GeminiService |
| **`appointments`** | `id`, `family_id`, `title`, `doctor_name`, `address`, `appointment_date`, `patient_name`, `photo_url` | HomeScreen (agenda médica) |
| **`gift_contributions`** | `id`, `mp_transaction_id`, `family_id`, `item_id`, `giver_name`, `giver_nickname`, `giver_phone`, `message_to_parents`, `thanked`, `thanked_by` (array de UUIDs), `created_at` | GiftsManagement, mp-webhook |
| **`user_settings`** | `user_id`, `due_date` | ShoppingListScreen (linha 80) — uso simples, tabela não essencial |

### Storage Buckets

| Bucket | Conteúdo | Usada em |
|--------|----------|----------|
| `avatars` | Fotos de perfil | ProfileSetupScreen |
| `diary_photos` | Fotos do diário + foto de perfil no Settings | DiaryScreen, SettingsScreen |
| `agenda_photos` | Documentos de consultas médicas | HomeScreen |
| `product_photos` | Fotos de produtos do enxoval | ShoppingListScreen |

---

## 3. REGRAS DE NEGÓCIO

### 3.1 Cálculo de Semanas Gestacionais (DUM)
- **Fórmula:** `semanas = floor(dias_desde_DUM / 7)`, limitado a 0–42
- **Onde:** `home_screen.dart:59–65`, `settings_screen.dart:44–49`, `shopping_list_screen.dart:173–176`
- **Shopping List** inverte a lógica: `weeks = 40 - floor(dias_ate_DueDate / 7)`
- Exibido como "X semanas + Y dias" nos ajustes

### 3.2 Dados Semanais do Bebê (Fruit Sizing)
- Tabela estática `baby_data.dart` mapeia semanas 4–41 → fruta, tamanho, peso
- Antes da semana 4: "Sementinha"
- Depois da semana 41: dados da semana 41
- Usado em `home_screen.dart:289`

### 3.3 Insights IA (Gemini)
- `gemini_service.dart`: modelo `gemini-2.5-flash`
- **getPregnancyInsights**: pede JSON com 5 chaves (body, nutrition, baby, mind, movement)
- **startChat**: histórico de conversas + contexto dinâmico (role, userName, babyName)
- Fallback estático: `pregnancy_ai_service.dart` — regras por trimestre:
  - <12: Adaptação e Formação
  - <20: Crescimento e Movimento
  - <28: Conexão e Desenvolvimento
  - >=28: Preparação para o Encontro

### 3.4 Sistema de Presentes (Fluxo Completo)
1. Pais adicionam itens na lista de enxoval
2. Pai/mãe marca `is_gift = true` → aparece na vitrine pública (`/presentes/:id`)
3. Visitante acessa → seleciona itens → preenche formulário (nome, email, telefone, mensagem)
4. `create-checkout-api` Edge Function calcula total → cria PIX no Mercado Pago (`/v1/payments`)
5. Frontend exibe QR Code, countdown 10min, polling a cada 3s (`pix_payment_screen.dart`)
6. Webhook `mp-webhook` recebe pagamento aprovado →:
   - Insere em `gift_contributions` com `mp_transaction_id = "{payment_id}_{item_id}"`
   - Atualiza item: `gift_status = 'received'`
   - Previne duplicata via `upsert` com `onConflict: mp_transaction_id`

### 3.5 Progresso de Agradecimento
- Cada presente exige **2 agradecimentos** (pai + mãe)
- Rastreado pelo array `thanked_by` (lista de UUIDs de usuários)
- `thankedCount >= 2` → presente totalmente agradecido
- Botão "Agradecer via WhatsApp" gera link `wa.me/{phone}?text=...`

### 3.6 Cálculos de Enxoval
- **Progresso por itens:** `boughtItems / totalItems` (%)
- **Progresso financeiro:** `totalSpent / totalEstimatedCost` (%)
- **Por categoria:** total gasto vs total estimado
- **Filtro por faixa etária:** 'Todos', 'RN', '1-3 Meses', '3-6 Meses', '6-9 Meses', '9-12 Meses', '1+ Ano'

### 3.7 Sistema de Família
- Primeiro usuário ao se registrar cria família com `invite_code` (6 chars aleatórios de A-Z, 0-9)
- Segundo usuário entra com código → associa ao mesmo `family_id`
- Roles: 'mae' ou 'pai'
- Tema do app: menino = azul (#64B5F6), menina = rosa (#F06292), neutro = roxo (deepPurple.shade300)

### 3.8 Web Scraping de Produtos
- `shopping_list_screen.dart:111–165`: `_scrapeLink(url)`
- Extrai `og:title`, `og:image`, e regex de preço em `R$ XX,XX`
- Desabilitado na Web (kIsWeb) para evitar CORS

### 3.9 Formulários de Checkout
- Validações em `checkout_form_validator.dart`:
  - Nome: obrigatório, mínimo 3 caracteres
  - Telefone: obrigatório, 10–11 dígitos
  - Mensagem: opcional, máximo 200 caracteres
  - Email: obrigatório, deve conter `@` e `.`

---

## 4. PENDÊNCIAS PARA MIGRAÇÃO

### Prioridade Critical (Core do App)
- [ ] **Autenticação** — Supabase Auth (email/senha + Google OAuth) em React Native
- [ ] **Auth Gate** — Router que decide entre Login / ProfileSetup / Main conforme sessao
- [ ] **Profile Setup** — Tela de cadastro inicial com upload de foto e opção de entrar via código de família
- [ ] **Main Screen Shell** — Tab navigator com 5 abas + stream em tempo real da família
- [ ] **Tema Dinâmico** — Color system baseado no sexo do bebê (menino→azul, menina→rosa, neutro→roxo)

### Telas — Navegação Principal
- [ ] **Home (Visão Geral da Gestação)** — Card de semana, fruta, tamanho, peso + avatares dos pais
- [ ] **Home (Insights IA)** — Cards horizontais com dados do Gemini (Corpo, Nutrição, Bebê, Mente, Movimento)
- [ ] **Home (Agenda Médica)** — Calendário (`table_calendar`), filtros (Dia/Próximas/Todas), CRUD de consultas com upload de foto
- [ ] **Enxoval (Shopping List)** — Progresso circular + financeiro, filtros por faixa etária, cards de categoria com barra de progresso, gráfico financeiro por categoria
- [ ] **Enxovel (Detail da Categoria)** — Lista de itens com checkbox, toggle is_gift, detalhes, edição, exclusão, link externo
- [ ] **Diário** — Stream de entries, mood icons, notas, peso, fotos, bubble de chat, edição inline
- [ ] **Presentes (Mural)** — Lista de contribuições, progresso de agradecimento (2/2), botão agradecer via WhatsApp
- [ ] **Ajustes** — Edição de perfil, DUM com cálculo de semanas, dados do bebê, link público, código de convite, parceiro, upload de foto, logout

### Telas — Web/Público (Web + Mobile)
- [ ] **Vitrine Pública de Presentes** (`/presentes/:id`) — Grid de produtos com botão "Presentear" (precisa funcionar como web app)
- [ ] **Checkout Web** (`/checkout/:id`) — Formulário do padrinho → gera PIX
- [ ] **Pagamento PIX** — QR Code, countdown 10 min, polling a cada 3s, tela de sucesso/timeout
- [ ] **Confirmação Pós-Pagamento** — Tela de agradecimento com nome do bebê

### Telas — Secundárias
- [ ] **Cadastro do Bebê** — Nome e sexo, pular para depois
- [ ] **Chatbot Cria AI** — Bubbles, histórico, Gemini session, disclaimer médico

### Serviços / Backend
- [ ] **Supabase Client** — Configurar `@supabase/supabase-js` com URL e Anon Key
- [ ] **Realtime Streams** — Mover de Supabase Stream (Flutter) para `.channel().subscribe()` (JS)
- [ ] **Edge Function: create-checkout-api** — Revisar/adaptar para React Native (já funciona via HTTP, deve ser compatível)
- [ ] **Edge Function: check-payment-status** — Já é REST, deve ser reutilizável
- [ ] **Edge Function: mp-webhook** — Já é REST, deve ser reutilizável
- [ ] **PaymentService** — Portar lógica de retry, timeout 30s, polling

### IA / Gemini
- [ ] **GeminiService** — Portar `getPregnancyInsights` (JSON parsing) + `startChat` (historical sessions) + `saveMessageToSupabase`
- [ ] **PregnancyAIService (fallback estático)** — Portar lógica de trimestres
- [ ] **BabyData** — Mapear tabela estática de frutas/semanas (semana 4 a 41)

### Funcionalidades Nativas
- [ ] **Image Picker** — Câmera + Galeria (equivalente ao `image_picker`)
- [ ] **URL Launcher** — Abrir Google Maps, links de produto, WhatsApp (equivalente a `url_launcher`)
- [ ] **QR Code** — Exibir QR Code do PIX (equivalente a `qr_flutter`)
- [ ] **Clipboard** — Copiar código PIX e códigos de convite
- [ ] **Web Hosting** — A app web precisa rodar `/presentes/:id` e `/checkout/:id` (Vercel ou similar)

### Integrações Externas
- [ ] **Mercado Pago API** — Checkout PIX (`/v1/payments`), verificação de status
- [ ] **Gemini API** — `gemini-2.5-flash` com system instructions dinâmicas
- [ ] **Google Maps** — Links de endereço das consultas
- [ ] **WhatsApp API** — Links `wa.me/{phone}?text=...`

### Utils / Design
- [ ] **AppColors** — Portar design tokens (bgTop, bgBottom, primaryPink, primaryPurple, etc)
- [ ] **formatBRL** — Formatação de moeda brasileira
- [ ] **CheckoutFormValidator** — Validações de nome, telefone, mensagem
- [ ] **WhatsAppHelper** — Generação de links de agradecimento
- [ ] **Web Scraping** — Avaliar se funciona no RN (pode precisar ir para Edge Function para evitar CORS)

### Questões para Decidir
- [ ] **Router** — Em Flutter usa `go_router`. Em RN: React Navigation? Expo Router?
- [ ] **State Management** — Em Flutter sem Provider explícito. Em RN: Zustand? Context?
- [ ] **Calendário** — `table_calendar` em Flutter → qual equivalente em RN? (`react-native-calendars`?)
- [ ] **Percent Indicators** — `percent_indicator` → qual lib em RN? (`react-native-circular-progress`?)
- [ ] **Google Fonts** — `google_fonts` → como portar para RN? (download manual? expo-font?)
- [ ] **Web Scraping no RN** — CORS impede requests diretos. Mover para Edge Function?
- [ ] **Deploy Web** — Onde hospedar as rotas públicas? (Atual: `web-jade-ten-51.vercel.app`)
- [ ] **Supabase RLS** — Validar políticas existentes continuam compatíveis
- [ ] **Foto de perfil no Settings** — Usa bucket `diary_photos` ao invés de `avatars`. Isso é intencional?
- [ ] **Múltiplos itens no checkout** — Edge function suporta array de items, mas UI só permite 1 item por transação atualmente.

---

## 5. DEPENDÊNCIAS — Mapeamento Flutter → Equivalente RN

| Flutter Package | Possível Equivalente RN | Uso |
|----------------|------------------------|-----|
| `supabase_flutter` | `@supabase/supabase-js` | Auth, DB, Storage, Realtime |
| `provider` | Context + hooks ou Zustand | Gerenciamento de estado |
| `go_router` | React Navigation ou Expo Router | Navegação + deep links |
| `intl` | `date-fns` ou `dayjs` | Formatação de datas pt_BR |
| `table_calendar` | `react-native-calendars` | Calendário de consultas |
| `image_picker` | `expo-image-picker` | Câmera e galeria |
| `url_launcher` | `expo-linking` / `Linking` | Abrir URLs externos |
| `percent_indicator` | `react-native-circular-progress` / `react-native-progress` | Barras de progresso |
| `google_fonts` | `expo-font` + download TTF | Fontes customizadas |
| `google_generative_ai` | `@google/generative-ai` (npm) | Gemini API |
| `qr_flutter` | `react-native-qrcode-svg` | Exibir QR Code |
| `http` | `fetch` / `axios` | HTTP requests |
| `url_strategy` | Config do router | URL strategy para web |
| `flutter_dotenv` | `react-native-dotenv` | Variáveis de ambiente |
| `flutter_localizations` | i18n library | Localização pt_BR |
