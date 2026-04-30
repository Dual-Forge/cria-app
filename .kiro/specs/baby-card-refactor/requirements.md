# Baby Card Refactor - Requisitos

## Visão Geral
Refatorar o "Cartão do Bebê" na tela principal (home_screen.dart) para substituir a imagem gerada por IA pela foto de perfil oficial dos pais e adicionar recursos interativos: Frequência Cardíaca (BPM) com áudio/animação, Barra de Progresso do Trimestre, Contador de Chutes e Signo Previsto.

## Objetivos Principais

### 1. Substituição da Imagem do Bebê
- **Remover**: Imagem fixa/gerada por IA do bebê (atualmente `_babyMonthAssetPath()`)
- **Adicionar**: Foto de perfil oficial selecionada pelos pais (`profile_photo_url` do banco de dados)
- **Fallback**: Ícone padrão caso a URL seja nula
- **Estilo**: ClipOval ou CircleAvatar com BoxFit.cover

### 2. Frequência Cardíaca (BPM) com Áudio e Animação
- **Campo de Dados**: `last_bpm` (inteiro) da tabela `baby_profile` ou `pregnancy_tracking`
- **Exibição**: Mostrar valor numérico do BPM com ícone de coração
- **Botão Play**: Ícone `Icons.play_arrow` para reproduzir áudio
- **Áudio Dinâmico**: 
  - Usar pacote `audioplayers` para reproduzir `assets/audio/heartbeat.mp3`
  - Calcular playback rate: `playbackRate = currentBpm / baseAudioBpm` (base = 120 BPM)
  - Aplicar rate antes do play: `audioPlayer.setPlaybackRate(playbackRate)`
  - Limitar rate entre 0.5 e 2.0 para segurança
- **Animação Visual**:
  - AnimationController com duração dinâmica: `(60000 / currentBpm).round()` ms
  - Ícone de coração (Icons.favorite) pulsando em rosa/vermelho
  - Sincronizar com o áudio (pulso visual = batida de áudio)
  - Dispose correto para evitar memory leaks

### 3. Barra de Progresso do Trimestre
- **Cálculo**: Função que calcula porcentagem de progresso do trimestre atual
  - 1º Trimestre: Semanas 1-13
  - 2º Trimestre: Semanas 14-27
  - 3º Trimestre: Semanas 28-40
  - Retorno: valor entre 0.0 e 1.0 + nome do trimestre (string)
- **UI**: LinearProgressIndicator estilizado com cores pastel (roxo/rosa)
- **Posicionamento**: Abaixo das informações de tamanho/peso
- **Rótulo**: Texto sutil indicando trimestre atual e porcentagem

### 4. Contador de Chutes
- **Campo de Dados**: `kick_count` (inteiro, default 0) da tabela `baby_profile`
- **Botão**: Discreto e elegante com texto "Registrar Chute 🦶"
- **Interação**:
  - Ao clicar, abrir AlertDialog: "Ayla chutou? Deseja registrar esse movimento?"
  - Botões: "Cancelar" e "Registrar"
  - Ao registrar: incrementar `kick_count` em +1 no Supabase
  - Atualizar UI com novo total
- **Estilo**: Bento design (clean, minimalista, cantos arredondados)

### 5. Signo Previsto (Zodíaco)
- **Entrada**: `expected_due_date` (data prevista do parto)
- **Função**: Calcular signo do zodíaco correspondente
- **Retorno**: String com nome do signo + emoji (ex: "♈ Áries")
- **UI**: Pequeno Chip ou Container arredondado
- **Posicionamento**: Canto superior direito do cartão ou ao lado do nome
- **Estilo**: Sutil e divertido

## Requisitos de Design (Bento Style)
- Layout clean e minimalista
- Cantos arredondados (BorderRadius.circular)
- Tons pastel (rosa, roxo, azul claro)
- Espaçamento consistente
- Sombras suaves
- Tipografia clara e hierárquica

## Requisitos de Banco de Dados
- Tabela `baby_profile` ou `pregnancy_tracking` deve ter:
  - `last_bpm` (inteiro, nullable)
  - `kick_count` (inteiro, default 0)
  - `profile_photo_url` (string, nullable)
  - `expected_due_date` (date)

## Requisitos de Dependências
- `audioplayers` (para reprodução de áudio)
- Arquivo de áudio: `assets/audio/heartbeat.mp3` (120 BPM base)

## Requisitos de Segurança
- Validar BPM entre 0.5x e 2.0x (playback rate)
- Dispose correto de AnimationController e AudioPlayer
- Tratamento de exceções para URLs de imagem inválidas
- Fallback para ícone padrão

## Requisitos de Performance
- Lazy loading de imagens
- Reutilização de AnimationController
- Evitar rebuilds desnecessários com RepaintBoundary
- Stream builders para dados em tempo real

## Requisitos de Acessibilidade
- Botões com tamanho mínimo de 48x48 dp
- Contraste adequado de cores
- Labels descritivos para ícones
- Suporte a leitura de tela

## Critérios de Aceitação
- [ ] Foto de perfil carrega corretamente do banco de dados
- [ ] BPM exibe com animação sincronizada ao áudio
- [ ] Playback rate ajusta dinamicamente com o BPM
- [ ] Barra de progresso mostra trimestre correto
- [ ] Contador de chutes incrementa e persiste no banco
- [ ] Signo do zodíaco calcula corretamente
- [ ] Sem memory leaks (dispose correto)
- [ ] Fallbacks funcionam para dados ausentes
- [ ] UI segue padrão Bento design
