import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

/// BPMDisplayWidget
///
/// Exibe a frequência cardíaca (BPM) com botão Play para reproduzir áudio.
/// Sincroniza animação visual com áudio dinâmico baseado no BPM.
class BPMDisplayWidget extends StatefulWidget {
  /// Frequência cardíaca em batidas por minuto (nullable)
  final int? lastBpm;

  /// Cor do tema para estilo
  final Color themeColor;

  /// BPM base do arquivo de áudio (padrão: 120)
  final double baseAudioBpm;

  /// Callback opcional quando o áudio começa
  final VoidCallback? onAudioStart;

  /// Callback opcional quando o áudio termina
  final VoidCallback? onAudioStop;

  /// Callback opcional para erros
  final Function(String error)? onError;

  const BPMDisplayWidget({
    super.key,
    this.lastBpm,
    required this.themeColor,
    this.baseAudioBpm = 120.0,
    this.onAudioStart,
    this.onAudioStop,
    this.onError,
  });

  @override
  State<BPMDisplayWidget> createState() => _BPMDisplayWidgetState();
}

class _BPMDisplayWidgetState extends State<BPMDisplayWidget>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  bool _isPlaying = false;
  String? _errorMessage;

  // Stream subscriptions for proper cleanup
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;

  // Constantes de segurança
  static const double _minBpm = 40.0;
  static const double _maxBpm = 200.0;
  static const double _minPlaybackRate = 0.5;
  static const double _maxPlaybackRate = 2.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeHeartAnimation();
    _setupAudioPlayerListeners();
  }

  /// Inicializa o AnimationController com duração dinâmica baseada no BPM
  void _initializeHeartAnimation() {
    final bpm = widget.lastBpm ?? 120;
    final durationMs = _calculateAnimationDuration(bpm);

    _heartController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    _heartScale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
  }

  /// Configura listeners para o AudioPlayer
  void _setupAudioPlayerListeners() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      PlayerState state,
    ) {
      if (state == PlayerState.playing) {
        setState(() => _isPlaying = true);
        widget.onAudioStart?.call();
        _heartController.repeat(reverse: true);
      } else if (state == PlayerState.stopped ||
          state == PlayerState.completed) {
        setState(() => _isPlaying = false);
        widget.onAudioStop?.call();
        _heartController.stop();
      }
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      setState(() => _isPlaying = false);
      widget.onAudioStop?.call();
      _heartController.stop();
    });
  }

  /// Calcula a duração da animação em milissegundos baseada no BPM
  int _calculateAnimationDuration(int bpm) {
    if (bpm <= 0) return 1000; // Fallback
    return (60000 / bpm).round();
  }

  /// Calcula o playback rate para o áudio
  double _calculatePlaybackRate(int bpm) {
    final rate = bpm / widget.baseAudioBpm;
    return rate.clamp(_minPlaybackRate, _maxPlaybackRate);
  }

  /// Valida o BPM
  bool _isValidBpm(int bpm) {
    return bpm >= _minBpm && bpm <= _maxBpm;
  }

  /// Reproduz o áudio do batimento cardíaco
  Future<void> _playHeartbeat() async {
    try {
      // Validar BPM
      if (widget.lastBpm == null) {
        _setError('BPM não disponível');
        return;
      }

      if (!_isValidBpm(widget.lastBpm!)) {
        _setError('BPM inválido: ${widget.lastBpm}');
        return;
      }

      // Calcular playback rate
      final playbackRate = _calculatePlaybackRate(widget.lastBpm!);

      // Aplicar playback rate
      await _audioPlayer.setPlaybackRate(playbackRate);

      // Atualizar duração da animação
      final durationMs = _calculateAnimationDuration(widget.lastBpm!);
      _heartController.duration = Duration(milliseconds: durationMs);

      // Reproduzir áudio
      await _audioPlayer.play(AssetSource('audio/heartbeat.mp3'));

      // Limpar erro anterior
      _setError(null);
    } catch (e) {
      _setError('Erro ao reproduzir áudio: $e');
      widget.onError?.call('Erro ao reproduzir áudio: $e');
    }
  }

  /// Para a reprodução do áudio
  Future<void> _stopHeartbeat() async {
    try {
      await _audioPlayer.stop();
      _heartController.stop();
      setState(() => _isPlaying = false);
    } catch (e) {
      _setError('Erro ao parar áudio: $e');
    }
  }

  /// Define mensagem de erro
  void _setError(String? error) {
    setState(() => _errorMessage = error);
  }

  @override
  void dispose() {
    // Cancel stream subscriptions to prevent memory leaks
    _playerStateSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    // Stop any ongoing audio playback
    _audioPlayer.stop();
    // Dispose the AudioPlayer instance
    _audioPlayer.dispose();
    // Cancel any pending animations
    _heartController.stop();
    // Dispose the AnimationController
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bpm = widget.lastBpm;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // BPM Display
        if (bpm != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _heartScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _heartScale.value,
                    child: Icon(Icons.favorite, color: Colors.red, size: 24),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                '$bpm BPM',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.themeColor,
                ),
              ),
            ],
          )
        else
          Text(
            'BPM não disponível',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        const SizedBox(height: 12),

        // Play Button
        if (bpm != null)
          ElevatedButton.icon(
            onPressed: _isPlaying ? _stopHeartbeat : _playHeartbeat,
            icon: Icon(
              _isPlaying ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
            ),
            label: Text(
              _isPlaying ? 'Parar' : 'Ouvir',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPlaying ? Colors.red : widget.themeColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

        // Error Message
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 12, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// BPMDisplayCompactWidget
///
/// Versão compacta do BPMDisplayWidget para espaços limitados.
class BPMDisplayCompactWidget extends StatefulWidget {
  /// Frequência cardíaca em batidas por minuto (nullable)
  final int? lastBpm;

  /// Cor do tema para estilo
  final Color themeColor;

  /// BPM base do arquivo de áudio (padrão: 120)
  final double baseAudioBpm;

  /// Callback opcional quando o áudio começa
  final VoidCallback? onAudioStart;

  /// Callback opcional quando o áudio termina
  final VoidCallback? onAudioStop;

  const BPMDisplayCompactWidget({
    super.key,
    this.lastBpm,
    required this.themeColor,
    this.baseAudioBpm = 120.0,
    this.onAudioStart,
    this.onAudioStop,
  });

  @override
  State<BPMDisplayCompactWidget> createState() =>
      _BPMDisplayCompactWidgetState();
}

class _BPMDisplayCompactWidgetState extends State<BPMDisplayCompactWidget>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  bool _isPlaying = false;

  // Stream subscriptions for proper cleanup
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;

  static const double _minBpm = 40.0;
  static const double _maxBpm = 200.0;
  static const double _minPlaybackRate = 0.5;
  static const double _maxPlaybackRate = 2.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeHeartAnimation();
    _setupAudioPlayerListeners();
  }

  void _initializeHeartAnimation() {
    final bpm = widget.lastBpm ?? 120;
    final durationMs = _calculateAnimationDuration(bpm);

    _heartController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    _heartScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
  }

  void _setupAudioPlayerListeners() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      PlayerState state,
    ) {
      if (state == PlayerState.playing) {
        setState(() => _isPlaying = true);
        widget.onAudioStart?.call();
        _heartController.repeat(reverse: true);
      } else if (state == PlayerState.stopped ||
          state == PlayerState.completed) {
        setState(() => _isPlaying = false);
        widget.onAudioStop?.call();
        _heartController.stop();
      }
    });
  }

  int _calculateAnimationDuration(int bpm) {
    if (bpm <= 0) return 1000;
    return (60000 / bpm).round();
  }

  double _calculatePlaybackRate(int bpm) {
    final rate = bpm / widget.baseAudioBpm;
    return rate.clamp(_minPlaybackRate, _maxPlaybackRate);
  }

  bool _isValidBpm(int bpm) {
    return bpm >= _minBpm && bpm <= _maxBpm;
  }

  Future<void> _playHeartbeat() async {
    try {
      if (widget.lastBpm == null || !_isValidBpm(widget.lastBpm!)) {
        return;
      }

      final playbackRate = _calculatePlaybackRate(widget.lastBpm!);
      await _audioPlayer.setPlaybackRate(playbackRate);

      final durationMs = _calculateAnimationDuration(widget.lastBpm!);
      _heartController.duration = Duration(milliseconds: durationMs);

      await _audioPlayer.play(AssetSource('audio/heartbeat.mp3'));
    } catch (e) {
      // Silenciosamente falhar em modo compacto
    }
  }

  Future<void> _stopHeartbeat() async {
    try {
      await _audioPlayer.stop();
      _heartController.stop();
      setState(() => _isPlaying = false);
    } catch (e) {
      // Silenciosamente falhar
    }
  }

  @override
  void dispose() {
    // Cancel stream subscriptions to prevent memory leaks
    _playerStateSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    // Stop any ongoing audio playback
    _audioPlayer.stop();
    // Dispose the AudioPlayer instance
    _audioPlayer.dispose();
    // Cancel any pending animations
    _heartController.stop();
    // Dispose the AnimationController
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bpm = widget.lastBpm;

    if (bpm == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _isPlaying ? _stopHeartbeat : _playHeartbeat,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.themeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.themeColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _heartScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _heartScale.value,
                  child: Icon(Icons.favorite, color: Colors.red, size: 16),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              '$bpm',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.themeColor,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _isPlaying ? Icons.stop : Icons.play_arrow,
              color: widget.themeColor,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
