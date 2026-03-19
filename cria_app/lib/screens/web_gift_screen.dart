import 'package:flutter/material.dart';
import 'package:cria_app/validators/checkout_form_validator.dart';
import 'package:cria_app/services/payment_service.dart';
import 'package:cria_app/screens/pix_payment_screen.dart';

class WebGiftScreen extends StatefulWidget {
  final PaymentService paymentService;
  final String familyId;
  final List<Map<String, dynamic>> selectedItems;

  const WebGiftScreen({
    Key? key,
    required this.paymentService,
    required this.familyId,
    required this.selectedItems,
  }) : super(key: key);

  @override
  State<WebGiftScreen> createState() => _WebGiftScreenState();
}

class _WebGiftScreenState extends State<WebGiftScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    print('Iniciando novo fluxo de checkout transparente...');
    if (!_formKey.currentState!.validate()) {
      return; // Se tiver erro de validação, para por aqui
    }

    setState(() => _isLoading = true);

    try {
      // Task 10.2: Chama o PaymentService com os dados do formulário
      final result = await widget.paymentService.createCheckout(
        items: widget.selectedItems,
        familyId: widget.familyId,
        giverName: _nameController.text.trim(),
        giverNickname: _nicknameController.text.trim(),
        giverPhone: _phoneController.text.trim(),
        messageToParents: _messageController.text.trim(),
      );

      if (!mounted) return;

      // Navega para a tela do PIX passando os dados retornados
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                validator: CheckoutFormValidator.validateName,
              ),
              const SizedBox(height: 16),

              // Campo Apelido (Opcional)
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Apelido (Opcional)',
                  border: OutlineInputBorder(),
                ),
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
                validator: CheckoutFormValidator.validatePhone,
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
                validator: CheckoutFormValidator.validateMessage,
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Gerar PIX', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}