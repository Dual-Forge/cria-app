import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/payment_service.dart';

class PixPaymentScreen extends StatefulWidget {
  final String paymentId;
  final String qrCode;
  final String qrCodeBase64;
  final String familyId;
  final PaymentService paymentService;

  const PixPaymentScreen({
    super.key,
    required this.paymentId,
    required this.qrCode,
    required this.qrCodeBase64,
    required this.familyId,
    required this.paymentService,
  });

  @override
  State<PixPaymentScreen> createState() => _PixPaymentScreenState();
}

class _PixPaymentScreenState extends State<PixPaymentScreen> {
  Timer? _countdownTimer;
  Timer? _pollingTimer;
  int _remainingSeconds = 600; // 10 minutos
  bool _isPolling = true;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startPolling();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _handleTimeout();
      }
    });
  }

  void _startPolling() {
    // Consulta o backend a cada 3 segundos
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isPolling) return;

      try {
        final result = await widget.paymentService.checkPaymentStatus(
          widget.paymentId,
        );

        if (result['status'] == 'approved') {
          _handleSuccess();
        }
      } catch (e) {
        debugPrint('Erro no polling: $e');
        // Mantém tentando na próxima rodada do timer
      }
    });
  }

  void _handleSuccess() {
    _isPolling = false;
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SuccessPlaceholderScreen()),
      );
    }
  }

  void _handleTimeout() {
    _isPolling = false;
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TimeoutPlaceholderScreen()),
      );
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.qrCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código PIX copiado!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento PIX'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Escaneie o QR Code abaixo para pagar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Task 8.2: Exibir QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: QrImageView(
                data: widget.qrCode,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Task 8.3: Timer de expiração
            Text(
              'Expira em: $_formattedTime',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Ou copie o código PIX (Pix Copia e Cola):',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Botão de Copiar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text('Copiar Código PIX'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Aguardando confirmação do pagamento...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PLACEHOLDERS (Pode substituir depois pelas telas reais)
// ==========================================
class SuccessPlaceholderScreen extends StatelessWidget {
  const SuccessPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Pagamento Aprovado! 🎉', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

class TimeoutPlaceholderScreen extends StatelessWidget {
  const TimeoutPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'O tempo do PIX expirou. ⌛',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
