import 'package:flutter/material.dart';
import 'package:cria_app/services/payment_service.dart';
import 'package:cria_app/screens/pix_payment_screen.dart';

class WebGiftScreen extends StatefulWidget {
  final PaymentService paymentService;
  final String familyId;
  final List<Map<String, dynamic>> selectedItems;

  const WebGiftScreen({
    super.key,
    required this.paymentService,
    required this.familyId,
    required this.selectedItems,
  });

  @override
  State<WebGiftScreen> createState() => _WebGiftScreenState();
}

class _WebGiftScreenState extends State<WebGiftScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(); // <--- NOVO CONTROLLER
  final _messageController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _emailController.dispose(); // <--- DISPOSE DO NOVO CONTROLLER
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await widget.paymentService.createCheckout(
        items: widget.selectedItems,
        familyId: widget.familyId,
        giverName: _nameController.text.trim(),
        giverNickname: _nicknameController.text.trim(),
        giverPhone: _phoneController.text.trim(),
        giverEmail: _emailController.text
            .trim(), // <--- ATENÇÃO AQUI: giverEmail (sem underscore)
        messageToParents: _messageController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PixPaymentScreen(
            paymentId: result['payment_id'].toString(),
            qrCode: result['qr_code'],
            qrCodeBase64: result['qr_code_base64'] ?? '',
            familyId: widget.familyId,
            paymentService: widget.paymentService,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presentear')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quem está presenteando?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Campo Nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Seu Nome Completo *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // Campo E-mail (NOVO)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail *',
                  border: OutlineInputBorder(),
                  hintText: 'Para receber o comprovante',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Campo obrigatório';
                  if (!val.contains('@') || !val.contains('.'))
                    return 'Digite um e-mail válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo Telefone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp (com DDD) *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 11987654321',
                ),
                keyboardType: TextInputType.phone,
                validator: (val) =>
                    val == null || val.length < 10 ? 'Telefone inválido' : null,
              ),
              const SizedBox(height: 16),

              // Campo Mensagem
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Deixe uma mensagem (Opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Botão Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Gerar PIX',
                          style: TextStyle(fontSize: 18, color: Colors.white),
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
