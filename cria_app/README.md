# 🐣 Cria — App de Acompanhamento de Gravidez

> Aplicativo Flutter para casais grávidos acompanharem cada semana da gestação, com IA especializada, diário, enxoval e sistema de presentes integrado ao Mercado Pago.

---

## ✨ Funcionalidades

| Módulo | Descrição |
|--------|-----------|
| **Gravidez** | Semana a semana com insights gerados por IA (Gemini 2.5 Flash) |
| **Nanda AI** | Chat com especialista virtual em maternidade e puerpério |
| **Diário** | Registro de humor, peso, notas e fotos |
| **Enxoval** | Lista de compras com scraping de preços e links de produtos |
| **Presentes** | Vitrine pública para padrinhos + pagamento PIX via Mercado Pago |
| **Agenda Médica** | Calendário de consultas com fotos e localização |

---

## 🏗️ Arquitetura

O projeto segue **Domain-Driven Design (Feature-First)** com separação clara entre UI, Services e Repositories:

```
lib/
├── core/                          # Global — compartilhado entre features
│   ├── config/env_config.dart     # Variáveis de ambiente (única fonte)
│   └── utils/                     # app_colors, price_formatter, whatsapp_helper
│
└── features/
    ├── baby/                      # Domínio: Bebê e Gestação
    │   ├── ui/                    # home_screen, appointments, baby_details
    │   ├── services/              # PregnancyCalculatorService, baby_data, zodiac
    │   └── repositories/          # BabyRepository (Supabase)
    │
    ├── parents/                   # Domínio: Pais e Configurações
    │   ├── ui/                    # settings, diary, timeline, login, profile_setup
    │   └── repositories/          # ProfileRepository (Supabase)
    │
    ├── ai_specialist/             # Domínio: IA (Nanda + Insights)
    │   ├── ui/                    # chatbot_screen
    │   ├── services/              # GeminiService, PregnancyAIService
    │   └── repositories/          # ChatRepository (chat_messages)
    │
    └── store_scraping/            # Domínio: Enxoval + Presentes + Pagamentos
        ├── ui/                    # shopping_list, gifts, public_registry, pix
        ├── services/              # ScrapingService, PaymentService
        └── repositories/          # ItemRepository (items, gift_contributions)
```

### Princípios Aplicados

- **DRY**: Cálculo de semanas gestacionais centralizado em `PregnancyCalculatorService`
- **SoC**: UI nunca acessa Supabase diretamente — usa Repositories
- **Segurança**: Todas as chaves via `EnvConfig` (`.env` local / `--dart-define` em CI)
- **Async**: Web scraping isolado no `ScrapingService` sem bloquear a UI

---

## 🚀 Pré-requisitos

| Ferramenta | Versão mínima |
|------------|---------------|
| Flutter SDK | ^3.10.1 |
| Dart SDK | ^3.10.1 |
| Android Studio / Xcode | Mais recente |
| Conta Supabase | — |
| Chave Gemini API | — |

---

## ⚙️ Configuração do Ambiente

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/cria.git
cd cria/cria_app
```

### 2. Instale as dependências

```bash
flutter pub get
```

### 3. Configure as variáveis de ambiente

```bash
cp .env.example .env
```

Edite o `.env` com suas chaves:

```dotenv
# Supabase — https://supabase.com/dashboard/project/_/settings/api
SUPABASE_URL=https://SEU_PROJETO.supabase.co
SUPABASE_ANON_KEY=sua_anon_key_aqui

# Gemini AI — https://aistudio.google.com/app/apikey
GEMINI_API_KEY=sua_gemini_api_key_aqui
```

> ⚠️ **NUNCA comite o arquivo `.env`** — ele está no `.gitignore`.

---

## 🏃 Executando o Projeto

### Desenvolvimento (Android/iOS)

```bash
flutter run
```

### Web (desenvolvimento)

```bash
flutter run -d chrome
```

### Web (Vercel — produção)

As variáveis de ambiente são injetadas via `--dart-define` no `vercel.json`. As chaves no `.env` NÃO são usadas em produção.

---

## 📦 Principais Dependências

| Pacote | Uso |
|--------|-----|
| `supabase_flutter` | Auth, banco de dados, storage, realtime |
| `google_generative_ai` | Gemini 2.5 Flash (chat e insights) |
| `flutter_dotenv` | Variáveis de ambiente locais |
| `go_router` | Navegação + deep links (rotas públicas `/presentes/:id`) |
| `table_calendar` | Agenda médica |
| `image_picker` | Câmera e galeria |
| `qr_flutter` | QR Code PIX |
| `google_fonts` | Tipografia (Nunito + Quicksand) |

---

## 🔒 Segurança

- Chaves de API **nunca** hardcoded — sempre via `EnvConfig`
- `.env` bloqueado no `.gitignore`
- Supabase Row Level Security (RLS) ativo em todas as tabelas
- Scraping de produtos **desabilitado na Web** para evitar CORS

---

## 📱 Plataformas Suportadas

| Plataforma | Status |
|------------|--------|
| Android | ✅ Suportado |
| iOS | ✅ Suportado |
| Web | ✅ Suportado (Vercel) |

---

## 🤝 Contribuindo

1. Crie uma branch: `git checkout -b feature/minha-feature`
2. Commit: `git commit -m 'feat: adiciona minha feature'`
3. Push: `git push origin feature/minha-feature`
4. Abra um Pull Request

---

*Feito com ❤️ para famílias em crescimento.*
