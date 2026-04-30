# Baby Card Refactor - Design Técnico

## Arquitetura de Alto Nível

### Estrutura de Componentes

```
HomePregnancyScreen
├── _buildOverviewTab()
│   └── BabyCardWidget (NOVO - Componente Refatorado)
│       ├── BabyProfileHeader
│       │   ├── ProfilePhotoWidget
│       │   ├── BPMDisplayWidget
│       │   └── ZodiacBadgeWidget
│       ├── TrimestreProgressBar
│       ├── KickCounterButton
│       └── BabyInfoFooter
```

### Fluxo de Dados

```
Supabase (baby_profile / pregnancy_tracking)
├── profile_photo_url → ProfilePhotoWidget
├── last_bpm → BPMDisplayWidget
├── kick_count → KickCounterButton
├── expected_due_date → ZodiacBadgeWidget
└── dum_date → TrimestreProgressBar
```

## Componentes Detalhados

### 1. ProfilePhotoWidget
**Responsabilidade**: Exibir foto de perfil com fallback

```dart
class ProfilePhotoWidget extends StatelessWidget {
  final String? photoUrl;
  final Color themeColor;
  final double size;
  
  // Lógica:
  // - Se photoUrl != null e válida: ClipOval + Image.network
  // - Se inválida ou null: CircleAvatar com ícone fallback
  // - BoxFit.cover para manter proporção
  // - ErrorBuilder para tratamento de erro
}
```

**Dados de Entrada**:
- `profile_photo_url` (string, nullable)
- `themeColor` (Color)

**Saída**: Widget com foto circular ou ícone fallback

---

### 2. BPMDisplayWidget
**Responsabilidade**: Exibir BPM com botão Play e gerenciar áudio/animação

```dart
class BPMDisplayWidget extends StatefulWidget {
  final int? lastBpm;
  final Color themeColor;
  
  // Estado:
  // - AudioPlayer instance
  // - AnimationController (duração dinâmica)
  // - isPlaying flag
}
```

**Lógica de Áudio Dinâmico**:
```dart
const double baseAudioBpm = 120.0;

Future<void> playHeartbeat(int currentBpm) async {
  // 1. Validar BPM
  if (currentBpm < 40 || currentBpm > 200) return;
  
  // 2. Calcular playback rate
  double playbackRate = currentBpm / baseAudioBpm;
  playbackRate = playbackRate.clamp(0.5, 2.0); // Segurança
  
  // 3. Aplicar rate
  await audioPlayer.setPlaybackRate(playbackRate);
  
  // 4. Reproduzir
  await audioPlayer.play(AssetSource('audio/heartbeat.mp3'));
  
  // 5. Sincronizar animação
  int durationMs = (60000 / currentBpm).round();
  animationController.duration = Duration(milliseconds: durationMs);
  animationController.repeat(reverse: true);
}
```

**Animação do Coração**:
```dart
// AnimationController com duração dinâmica
_heartController = AnimationController(
  vsync: this,
  duration: Duration(milliseconds: (60000 / currentBpm).round()),
)..repeat(reverse: true);

// Tween para escala
_heartScale = Tween<double>(begin: 0.9, end: 1.1).animate(
  CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
);

// Widget com Transform.scale
Transform.scale(
  scale: _heartScale.value,
  child: Icon(Icons.favorite, color: Colors.red, size: 40),
)
```

**Dispose**:
```dart
@override
void dispose() {
  audioPlayer.dispose();
  _heartController.dispose();
  super.dispose();
}
```

**Dados de Entrada**:
- `last_bpm` (int, nullable)
- `themeColor` (Color)

**Saída**: Widget com BPM, botão Play, animação sincronizada

---

### 3. TrimestreProgressBar
**Responsabilidade**: Calcular e exibir progresso do trimestre

```dart
class TrimestreProgressBar extends StatelessWidget {
  final DateTime? dumDate;
  final Color themeColor;
  
  // Lógica:
  // - Calcular semana gestacional atual
  // - Determinar trimestre (1-3)
  // - Calcular progresso (0.0-1.0)
  // - Exibir LinearProgressIndicator + rótulo
}
```

**Função de Cálculo**:
```dart
Map<String, dynamic> calculateTrimestreProgress(DateTime? dumDate) {
  if (dumDate == null) return {'progress': 0.0, 'trimestre': 'N/A'};
  
  int weeks = _calculateWeeks(dumDate);
  
  String trimestre;
  double progress;
  
  if (weeks <= 13) {
    trimestre = '1º Trimestre';
    progress = weeks / 13.0;
  } else if (weeks <= 27) {
    trimestre = '2º Trimestre';
    progress = (weeks - 13) / 14.0;
  } else {
    trimestre = '3º Trimestre';
    progress = (weeks - 27) / 13.0;
  }
  
  progress = progress.clamp(0.0, 1.0);
  
  return {
    'progress': progress,
    'trimestre': trimestre,
    'percentage': (progress * 100).toStringAsFixed(0),
  };
}
```

**UI**:
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('${trimestre} - ${percentage}%'),
    LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.grey[200],
      valueColor: AlwaysStoppedAnimation(themeColor),
      minHeight: 8,
      borderRadius: BorderRadius.circular(4),
    ),
  ],
)
```

**Dados de Entrada**:
- `dum_date` (DateTime)
- `themeColor` (Color)

**Saída**: Widget com barra de progresso + rótulo

---

### 4. KickCounterButton
**Responsabilidade**: Gerenciar contador de chutes com persistência

```dart
class KickCounterButton extends StatefulWidget {
  final int kickCount;
  final String babyName;
  final String familyId;
  final Color themeColor;
  
  // Estado:
  // - kickCount local
  // - isLoading flag
}
```

**Lógica de Incremento**:
```dart
Future<void> registerKick() async {
  // 1. Mostrar AlertDialog
  bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${babyName} chutou?'),
      content: const Text('Deseja registrar esse movimento?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Registrar'),
        ),
      ],
    ),
  );
  
  if (confirmed != true) return;
  
  // 2. Atualizar Supabase
  try {
    await supabase
        .from('baby_profile')
        .update({'kick_count': kickCount + 1})
        .eq('family_id', familyId);
    
    // 3. Atualizar UI
    setState(() => kickCount++);
    
    // 4. Feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chute registrado! Total: ${kickCount + 1}')),
    );
  } catch (e) {
    // Tratamento de erro
  }
}
```

**UI**:
```dart
ElevatedButton.icon(
  onPressed: registerKick,
  icon: const Text('🦶', style: TextStyle(fontSize: 18)),
  label: Text('Registrar Chute ($kickCount)'),
  style: ElevatedButton.styleFrom(
    backgroundColor: themeColor.withOpacity(0.1),
    foregroundColor: themeColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
)
```

**Dados de Entrada**:
- `kick_count` (int)
- `babyName` (string)
- `familyId` (string)
- `themeColor` (Color)

**Saída**: Widget com botão interativo + contador

---

### 5. ZodiacBadgeWidget
**Responsabilidade**: Calcular e exibir signo do zodíaco

```dart
class ZodiacBadgeWidget extends StatelessWidget {
  final DateTime? expectedDueDate;
  
  // Lógica:
  // - Calcular signo baseado na data
  // - Retornar nome + emoji
  // - Exibir em Chip/Container
}
```

**Função de Cálculo**:
```dart
Map<String, String> getZodiacSign(DateTime? dueDate) {
  if (dueDate == null) return {'sign': 'N/A', 'emoji': '♈'};
  
  int month = dueDate.month;
  int day = dueDate.day;
  
  // Tabela de signos
  const zodiacSigns = {
    'Áries': {'emoji': '♈', 'start': (3, 21), 'end': (4, 19)},
    'Touro': {'emoji': '♉', 'start': (4, 20), 'end': (5, 20)},
    'Gêmeos': {'emoji': '♊', 'start': (5, 21), 'end': (6, 20)},
    'Câncer': {'emoji': '♋', 'start': (6, 21), 'end': (7, 22)},
    'Leão': {'emoji': '♌', 'start': (7, 23), 'end': (8, 22)},
    'Virgem': {'emoji': '♍', 'start': (8, 23), 'end': (9, 22)},
    'Libra': {'emoji': '♎', 'start': (9, 23), 'end': (10, 22)},
    'Escorpião': {'emoji': '♏', 'start': (10, 23), 'end': (11, 21)},
    'Sagitário': {'emoji': '♐', 'start': (11, 22), 'end': (12, 21)},
    'Capricórnio': {'emoji': '♑', 'start': (12, 22), 'end': (1, 19)},
    'Aquário': {'emoji': '♒', 'start': (1, 20), 'end': (2, 18)},
    'Peixes': {'emoji': '♓', 'start': (2, 19), 'end': (3, 20)},
  };
  
  // Lógica de matching
  for (var entry in zodiacSigns.entries) {
    // Implementar lógica de range
  }
  
  return {'sign': 'Áries', 'emoji': '♈'};
}
```

**UI**:
```dart
Chip(
  label: Text('${zodiac['emoji']} ${zodiac['sign']}'),
  backgroundColor: themeColor.withOpacity(0.1),
  labelStyle: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
)
```

**Dados de Entrada**:
- `expected_due_date` (DateTime)

**Saída**: Widget com signo + emoji

---

## Integração com HomePregnancyScreen

### Modificações Necessárias

1. **Remover**: Código de `_babyMonthAssetPath()` e imagem fixa
2. **Adicionar**: Novos widgets como componentes
3. **Refatorar**: `_buildOverviewTab()` para usar novos componentes
4. **Atualizar**: Stream builders para incluir novos campos

### Exemplo de Integração

```dart
// Antes (atual)
Container(
  width: 130,
  height: 130,
  child: ClipOval(
    child: Image.asset(_babyMonthAssetPath(...)),
  ),
)

// Depois (novo)
ProfilePhotoWidget(
  photoUrl: momProfile?['profile_photo_url'],
  themeColor: widget.themeColor,
  size: 130,
)
```

---

## Estrutura de Arquivos

```
cria_app/lib/
├── widgets/
│   ├── baby_card/
│   │   ├── baby_card_widget.dart (componente principal)
│   │   ├── profile_photo_widget.dart
│   │   ├── bpm_display_widget.dart
│   │   ├── trimestre_progress_bar.dart
│   │   ├── kick_counter_button.dart
│   │   └── zodiac_badge_widget.dart
│   └── ...
├── utils/
│   ├── zodiac_calculator.dart (função de cálculo)
│   ├── trimestre_calculator.dart (função de cálculo)
│   └── ...
└── screens/
    └── home_screen.dart (refatorado)
```

---

## Dependências Necessárias

### Adicionar ao pubspec.yaml
```yaml
dependencies:
  audioplayers: ^5.2.0
```

### Assets Necessários
```
assets/
└── audio/
    └── heartbeat.mp3 (120 BPM base)
```

---

## Considerações de Performance

1. **Lazy Loading**: Imagens carregadas sob demanda
2. **RepaintBoundary**: Envolver animações para otimizar rebuilds
3. **Stream Builders**: Usar para dados em tempo real
4. **Dispose Correto**: Liberar recursos de AnimationController e AudioPlayer
5. **Memoization**: Cachear cálculos de zodíaco e trimestre

---

## Considerações de Segurança

1. **Validação de BPM**: Limitar entre 40-200 BPM (0.5x-2.0x playback rate)
2. **Tratamento de Exceções**: Try-catch para operações de Supabase
3. **Fallbacks**: Ícones padrão para dados ausentes
4. **Permissões**: Verificar acesso a áudio antes de reproduzir

---

## Testes Necessários

1. **Unit Tests**:
   - `zodiac_calculator_test.dart`
   - `trimestre_calculator_test.dart`

2. **Widget Tests**:
   - `profile_photo_widget_test.dart`
   - `bpm_display_widget_test.dart`
   - `kick_counter_button_test.dart`

3. **Integration Tests**:
   - Fluxo completo de registro de chute
   - Reprodução de áudio com diferentes BPMs
   - Carregamento de foto de perfil

---

## Roadmap de Implementação

**Fase 1**: Componentes base (ProfilePhotoWidget, ZodiacBadgeWidget)
**Fase 2**: Lógica de áudio (BPMDisplayWidget)
**Fase 3**: Interatividade (KickCounterButton, TrimestreProgressBar)
**Fase 4**: Integração e testes
**Fase 5**: Refinamento de UI/UX
