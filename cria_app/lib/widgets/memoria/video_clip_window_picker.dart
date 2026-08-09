import 'package:flutter/material.dart';

/// Constantes compartilhadas de recorte de vídeo.
abstract final class VideoClipLimits {
  static const int maxClipMs = 60 * 1000; // 1 minuto
  static const int minClipMs = 1000; // 1 segundo mínimo
}

/// Tipo de arrasto ativo no [VideoClipWindowPicker].
enum _Drag { none, left, right, window }

/// Seletor interativo de janela de vídeo (trimmer).
///
/// Permite arrastar as alças esquerda/direita para escolher exatamente qual
/// trecho (de no máximo [VideoClipLimits.maxClipMs]) do vídeo original deve
/// ser enviado. Também permite arrastar a janela inteira para reposicioná-la.
///
/// 100% Flutter — funciona igualmente em Web e mobile, sem recodificação.
/// O "corte" é feito por metadados: o arquivo original fica no storage e o
/// app reproduz apenas o intervalo escolhido.
class VideoClipWindowPicker extends StatefulWidget {
  final Duration totalDuration;
  final ValueChanged<(int startMs, int endMs)>? onClipChanged;

  const VideoClipWindowPicker({
    super.key,
    required this.totalDuration,
    this.onClipChanged,
  });

  @override
  State<VideoClipWindowPicker> createState() => _VideoClipWindowPickerState();
}

class _VideoClipWindowPickerState extends State<VideoClipWindowPicker> {
  static const double _trackHeight = 56;
  static const double _handleZonePx = 28; // Faixa de captura de cada alça.

  late int _totalMs;
  late int _startMs;
  late int _endMs;

  _Drag _drag = _Drag.none;

  @override
  void initState() {
    super.initState();
    _totalMs = widget.totalDuration.inMilliseconds;
    _startMs = 0;
    // Janela inicial = o que couber (no máx 60s) do início do vídeo.
    _endMs = _totalMs.clamp(0, VideoClipLimits.maxClipMs);
    _emit();
  }

  void _emit() => widget.onClipChanged?.call((_startMs, _endMs));

  int _msAtPx(double px, double trackWidth) =>
      (px.clamp(0.0, trackWidth) * _totalMs / trackWidth).round();

  double _pxAtMs(int ms, double trackWidth) => ms / _totalMs * trackWidth;

  /// Identifica qual elemento será arrastado a partir de onde o gesto começou.
  void _onDragStart(DragStartDetails d, double trackWidth) {
    final x = d.localPosition.dx;
    final leftPx = _pxAtMs(_startMs, trackWidth);
    final rightPx = _pxAtMs(_endMs, trackWidth);

    if ((x - leftPx).abs() <= _handleZonePx) {
      _drag = _Drag.left;
    } else if ((x - rightPx).abs() <= _handleZonePx) {
      _drag = _Drag.right;
    } else if (x > leftPx && x < rightPx) {
      _drag = _Drag.window;
    } else {
      _drag = _Drag.none;
    }
  }

  void _onDragUpdate(DragUpdateDetails d, double trackWidth) {
    switch (_drag) {
      case _Drag.left:
        _startMs = _msAtPx(d.localPosition.dx, trackWidth);
      case _Drag.right:
        _endMs = _msAtPx(d.localPosition.dx, trackWidth);
      case _Drag.window:
        final len = _endMs - _startMs;
        final deltaMs = (d.delta.dx * _totalMs / trackWidth).round();
        var newStart = _startMs + deltaMs;
        var newEnd = _endMs + deltaMs;
        if (newStart < 0) {
          newStart = 0;
          newEnd = newStart + len;
        }
        if (newEnd > _totalMs) {
          newEnd = _totalMs;
          newStart = newEnd - len;
        }
        _startMs = newStart;
        _endMs = newEnd;
      case _Drag.none:
        return;
    }
    _clampSelection();
    setState(() {});
  }

  void _resolveOverlap() {
    final minLen = (VideoClipLimits.minClipMs).clamp(1, _totalMs);
    if (_endMs - _startMs < minLen) {
      // Mantém a janela miníma ancorada na alça que está sendo arrastada.
      if (_drag == _Drag.right || _drag == _Drag.window) {
        _endMs = (_startMs + minLen).clamp(0, _totalMs);
        _startMs = _endMs - minLen;
      } else {
        _startMs = (_endMs - minLen).clamp(0, _totalMs);
        _endMs = (_startMs + minLen).clamp(0, _totalMs);
      }
    }
  }

  void _clampSelection() {
    // Limites do vídeo.
    if (_startMs < 0) _startMs = 0;
    if (_startMs > _totalMs) _startMs = _totalMs;
    if (_endMs < 0) _endMs = 0;
    if (_endMs > _totalMs) _endMs = _totalMs;
    if (_startMs > _endMs) {
      // Alças cruzaram; desfaz invertendo a ordem.
      final minLen = (VideoClipLimits.minClipMs).clamp(1, _totalMs);
      _endMs = (_startMs + minLen).clamp(0, _totalMs);
    }
    _resolveOverlap();
    // Máximo de 1 minuto.
    final len = _endMs - _startMs;
    if (len > VideoClipLimits.maxClipMs) {
      if (_drag == _Drag.left) {
        _startMs = _endMs - VideoClipLimits.maxClipMs;
      } else {
        _endMs = _startMs + VideoClipLimits.maxClipMs;
      }
    }
    _emit();
  }

  void _dragEnd() => _drag = _Drag.none;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => _onDragStart(d, trackWidth),
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, trackWidth),
          onHorizontalDragEnd: (_) => _dragEnd(),
          onHorizontalDragCancel: _dragEnd,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _trackHeight,
                width: trackWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildTrackBackground(trackWidth),
                    _buildSelectionWindow(trackWidth),
                    _buildHandle(_pxAtMs(_startMs, trackWidth), isLeft: true),
                    _buildHandle(_pxAtMs(_endMs, trackWidth), isLeft: false),
                    IgnorePointer(
                      child: Positioned.fill(
                        child: CustomPaint(painter: _TickPainter(_totalMs)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildTimeLabels(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackBackground(double trackWidth) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.withValues(alpha: 0.10),
                Colors.deepPurple.shade50,
                Colors.deepPurple.withValues(alpha: 0.10),
              ],
            ),
            border: Border.all(color: Colors.deepPurple.shade200),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionWindow(double trackWidth) {
    final left = _pxAtMs(_startMs, trackWidth);
    final right = _pxAtMs(_endMs, trackWidth);
    return Positioned(
      left: left,
      width: (right - left).clamp(0.0, trackWidth),
      top: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepPurple.shade300, width: 2),
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.withValues(alpha: 0.35),
              Colors.deepPurple.shade300.withValues(alpha: 0.45),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(double px, {required bool isLeft}) {
    return Positioned(
      left: px - 10,
      top: -4,
      bottom: -4,
      child: Container(
        width: 22,
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.deepPurple.shade300, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Center(
          child: Icon(
            isLeft ? Icons.chevron_left : Icons.chevron_right,
            color: Colors.deepPurple.shade700,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeLabels() {
    String fmt(int ms) {
      final s = (ms / 1000).round();
      final m = s ~/ 60;
      final r = s % 60;
      final sec = r.toString().padLeft(2, '0');
      return m > 0 ? '$m:$sec' : '0:$sec';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          fmt(_startMs),
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
        ),
        Text(
          '${fmt(_endMs - _startMs)} de ${fmt(VideoClipLimits.maxClipMs)}',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.deepPurple.shade300, fontWeight: FontWeight.w600, fontSize: 12),
        ),
        Text(
          fmt(_endMs),
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

/// Desenha pequenas marcas de tick a cada segundo na faixa.
class _TickPainter extends CustomPainter {
  final int totalMs;
  const _TickPainter(this.totalMs);

  @override
  void paint(Canvas canvas, Size size) {
    // Ticks maiores (a cada 5s) e menores (a cada 1s) — legíveis mas sem
    // virar uma "faixa listrada" densa.
    final majorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.5;
    final minorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    const majorStep = 5; // a cada 5 segundos
    final totalSeconds = (totalMs / 1000).ceil();
    for (int s = 0; s <= totalSeconds; s++) {
      final x = size.width * s / totalSeconds;
      if (s % majorStep == 0) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorPaint);
      } else {
        canvas.drawLine(Offset(x, size.height * 0.3), Offset(x, size.height * 0.7), minorPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TickPainter old) => old.totalMs != totalMs;
}