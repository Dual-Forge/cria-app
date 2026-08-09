import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// KickCounterButton
/// 
/// Botão interativo para registrar chutes do bebê com persistência no Supabase.
/// Exibe contador de chutes e permite incrementar com confirmação.
class KickCounterButton extends StatefulWidget {
  /// Contador de chutes atual
  final int kickCount;

  /// Nome do bebê para exibição
  final String babyName;

  /// ID da família para atualizar no Supabase
  final String familyId;

  /// Cor do tema para estilo
  final Color themeColor;

  /// Callback opcional quando o contador é atualizado
  final Function(int newCount)? onKickCountUpdated;

  /// Callback opcional para erros
  final Function(String error)? onError;

  /// Callback opcional quando o carregamento começa/termina
  final Function(bool isLoading)? onLoadingChanged;

  const KickCounterButton({
    super.key,
    required this.kickCount,
    required this.babyName,
    required this.familyId,
    required this.themeColor,
    this.onKickCountUpdated,
    this.onError,
    this.onLoadingChanged,
  });

  @override
  State<KickCounterButton> createState() => _KickCounterButtonState();
}

class _KickCounterButtonState extends State<KickCounterButton> {
  late int _localKickCount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _localKickCount = widget.kickCount;
  }

  @override
  void didUpdateWidget(KickCounterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kickCount != widget.kickCount) {
      _localKickCount = widget.kickCount;
    }
  }

  /// Registra um novo chute
  Future<void> _registerKick() async {
    if (widget.familyId.trim().isEmpty) {
      const message = 'Família inválida para registrar chute.';
      widget.onError?.call(message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Mostrar diálogo de confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.babyName} chutou?'),
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

    // Iniciar carregamento
    _setLoading(true);

    try {
      final supabase = Supabase.instance.client;
      final newCount = _localKickCount + 1;

      // Atualizar no Supabase
      await supabase
          .from('baby_profile')
          .update({'kick_count': newCount})
          .eq('family_id', widget.familyId);

      // Atualizar estado local
      setState(() => _localKickCount = newCount);

      // Callback
      widget.onKickCountUpdated?.call(newCount);

      // Mostrar feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chute registrado! Total: $newCount'),
            duration: const Duration(seconds: 2),
            backgroundColor: widget.themeColor,
          ),
        );
      }
    } catch (e) {
      // Tratamento de erro
      final errorMessage = 'Erro ao registrar chute: $e';
      widget.onError?.call(errorMessage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Define o estado de carregamento
  void _setLoading(bool isLoading) {
    if (!mounted) return;
    setState(() => _isLoading = isLoading);
    widget.onLoadingChanged?.call(isLoading);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _registerKick,
      icon: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.themeColor,
                ),
              ),
            )
          : const Text(
              '🦶',
              style: TextStyle(fontSize: 18),
            ),
      label: Text(
        'Registrar Chute ($_localKickCount)',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.themeColor.withOpacity(0.1),
        foregroundColor: widget.themeColor,
        disabledBackgroundColor: Colors.grey[200],
        disabledForegroundColor: Colors.grey[400],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: widget.themeColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
    );
  }
}

/// KickCounterCompactButton
/// 
/// Versão compacta do botão de contador de chutes.
class KickCounterCompactButton extends StatefulWidget {
  /// Contador de chutes atual
  final int kickCount;

  /// Nome do bebê para exibição
  final String babyName;

  /// ID da família para atualizar no Supabase
  final String familyId;

  /// Cor do tema para estilo
  final Color themeColor;

  /// Callback opcional quando o contador é atualizado
  final Function(int newCount)? onKickCountUpdated;

  /// Mostrar em modo flat (sem bordas/fundo) para aninhar em outros containers
  final bool isFlat;

  const KickCounterCompactButton({
    super.key,
    required this.kickCount,
    required this.babyName,
    required this.familyId,
    required this.themeColor,
    this.onKickCountUpdated,
    this.isFlat = false,
  });

  @override
  State<KickCounterCompactButton> createState() =>
      _KickCounterCompactButtonState();
}

class _KickCounterCompactButtonState extends State<KickCounterCompactButton> {
  late int _localKickCount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _localKickCount = widget.kickCount;
  }

  Future<void> _registerKick() async {
    if (widget.familyId.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Família inválida para registrar chute.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.babyName} chutou?'),
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

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final newCount = _localKickCount + 1;

      await supabase
          .from('baby_profile')
          .update({'kick_count': newCount})
          .eq('family_id', widget.familyId);

      setState(() => _localKickCount = newCount);
      widget.onKickCountUpdated?.call(newCount);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chute registrado! Total: $newCount'),
            duration: const Duration(seconds: 2),
            backgroundColor: widget.themeColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar chute: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _registerKick,
      child: Container(
        padding: widget.isFlat ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: widget.isFlat
            ? null
            : BoxDecoration(
                color: widget.themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.themeColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.themeColor,
                  ),
                ),
              )
            else
              Text(
                widget.isFlat ? '👣' : '🦶',
                style: TextStyle(fontSize: widget.isFlat ? 12 : 14),
              ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.isFlat ? '$_localKickCount chutes' : _localKickCount.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: widget.themeColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// KickCounterDisplayWidget
/// 
/// Widget apenas para exibição do contador de chutes (sem interatividade).
class KickCounterDisplayWidget extends StatelessWidget {
  /// Contador de chutes atual
  final int kickCount;

  /// Cor do tema para estilo
  final Color themeColor;

  /// Mostrar ícone
  final bool showIcon;

  /// Tamanho do texto
  final double textSize;

  const KickCounterDisplayWidget({
    super.key,
    required this.kickCount,
    required this.themeColor,
    this.showIcon = true,
    this.textSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon)
            Text(
              '🦶',
              style: TextStyle(fontSize: textSize),
            ),
          if (showIcon) const SizedBox(width: 6),
          Text(
            kickCount.toString(),
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// KickCounterHistoryWidget
/// 
/// Widget para exibir histórico de chutes com data/hora.
class KickCounterHistoryWidget extends StatelessWidget {
  /// Contador de chutes atual
  final int kickCount;

  /// Data do último chute
  final DateTime? lastKickDate;

  /// Cor do tema para estilo
  final Color themeColor;

  const KickCounterHistoryWidget({
    super.key,
    required this.kickCount,
    this.lastKickDate,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                '🦶',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'Total de chutes: $kickCount',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ],
          ),
          if (lastKickDate != null) ...[
            const SizedBox(height: 6),
            Text(
              'Último chute: ${_formatDateTime(lastKickDate!)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (difference.inMinutes < 60) {
      return 'Há ${difference.inMinutes} minuto(s)';
    } else if (difference.inHours < 24) {
      return 'Há ${difference.inHours} hora(s)';
    } else if (difference.inDays < 7) {
      return 'Há ${difference.inDays} dia(s)';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
