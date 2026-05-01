# Cria App - Controle de Gestação

Aplicativo Flutter para acompanhamento de gestação, com recursos de IA, lista de presentes e controle de desenvolvimento do bebê.

## Componentes Principais

### Baby Card Widget

O `BabyCardWidget` é o componente principal que exibe as informações do bebê no modo Bento design (cards com cantos arredondados, cores pastel).

**Localização:** `lib/widgets/baby_card/baby_card_widget.dart`

**Sub-componentes:**

1. **ProfilePhotoWidget** (`profile_photo_widget.dart`)
   - Exibe foto de perfil com `ClipOval`
   - Fallback para ícone padrão se URL inválida
   - Tratamento de erro com `onImageError` callback

2. **BPMDisplayWidget** (`bpm_display_widget.dart`)
   - Reproduz áudio de batimento cardíaco (120 BPM base)
   - Cálculo dinâmico de `playback rate` baseado no BPM (40-200 BPM)
   - Animação sincronizada com áudio
   - `AudioPlayer` com dispose correto

3. **ZodiacBadgeWidget** (`zodiac_badge_widget.dart`)
   - Calcula signo baseado na `expected_due_date`
   - Exibe Chip com signo + emoji
   - Estilo Bento (cores pastel, arredondado)

4. **TrimestreProgressBar** (`trimestre_progress_bar.dart`)
   - Calcula progresso do trimestre baseado na DUM (Data da Última Menstruação)
   - `LinearProgressIndicator` estilizado
   - Exibe rótulo com trimestre + porcentagem

5. **KickCounterButton** (`kick_counter_button.dart`)
   - Botão "Registrar Chute 🦶"
   - `AlertDialog` de confirmação
   - Incrementa `kick_count` no Supabase
   - Feedback visual com `SnackBar`

## Banco de Dados

Tabela `baby_profile` com os seguintes campos:

```sql
- id: UUID (PK)
- family_id: UUID (FK -> families)
- profile_photo_url: TEXT (nullable)
- last_bpm: INTEGER (40-200, nullable)
- kick_count: INTEGER (default 0)
- expected_due_date: DATE
- created_at: TIMESTAMPTZ
- updated_at: TIMESTAMPTZ
```

**RLS Policies configuradas:**
- Leitura: Usuário pode ler se pertence à família
- Escrita: Usuário pode atualizar/inserir se pertence à família

## Utilitários

- **ZodiacCalculator** (`lib/utils/zodiac_calculator.dart`): Calcula signo do zodíaco
- **TrimestreCalculator** (`lib/utils/trimestre_calculator.dart`): Calcula trimestre e progresso

## Testes

Execute todos os testes com:
```bash
cd cria_app
flutter test
```

**Cobertura:**
- Testes unitários para utilitários (zodiac, trimestre)
- Testes de widget para todos os componentes do baby card
- Testes de integração com Supabase (mockados)
- Total: 240 testes passando

## Dependências Principais

- `audioplayers: ^5.2.0` - Reprodução de áudio
- `supabase_flutter` - Backend e autenticação
- `google_fonts` - Tipografia
- `table_calendar` - Calendário na HomeScreen

## Como Executar

1. Instale as dependências: `flutter pub get`
2. Configure as variáveis do Supabase em `lib/main.dart`
3. Execute: `flutter run`

## Estrutura de Pastas

```
cria_app/lib/
├── screens/          # Telas (Home, Login, Registro, etc.)
├── widgets/          # Widgets reutilizáveis (baby_card/, etc.)
├── utils/            # Utilitários e calculadoras
├── services/         # Serviços (Supabase, Pagamentos, IA)
├── models/           # Modelos de dados
└── validators/       # Validadores de formulário
```
