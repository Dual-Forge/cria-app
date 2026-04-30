import 'package:flutter/material.dart';

class ConfirmationScreen extends StatelessWidget {
  final String babyName;
  final VoidCallback? onReturnHome;

  const ConfirmationScreen({
    super.key,
    required this.babyName,
    this.onReturnHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícone de Sucesso
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 32),

              // Título
              const Text(
                'Pagamento Aprovado! 🎉',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Mensagem personalizada com o nome do bebê
              Text(
                'Muito obrigado pelo presente!\n$babyName vai adorar!',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Botão de retorno
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (onReturnHome != null) {
                      onReturnHome!();
                    } else {
                      // Comportamento padrão: remove todas as telas empilhadas e volta pra Home
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors
                        .blueAccent, // Pode ajustar para a cor tema do seu app
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Voltar para lista de presentes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
