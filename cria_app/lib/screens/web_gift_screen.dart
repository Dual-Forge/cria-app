import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';
import '../utils/price_formatter.dart';

const int kWeeksPregnancy = 20;
const int kInstallments = 6;

class WebGiftScreen extends StatefulWidget {
  final String familyId;
  const WebGiftScreen({super.key, required this.familyId});

  @override
  State<WebGiftScreen> createState() => _WebGiftScreenState();
}

class _WebGiftScreenState extends State<WebGiftScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _familyData;
  List<Map<String, dynamic>> _giftItems = [];
  final List<Map<String, dynamic>> _cartItems = [];

  final _gridKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final client = Supabase.instance.client;
      final familyResponse = await client
          .from('families')
          .select('baby_name, pix_key, created_at')
          .eq('id', widget.familyId)
          .maybeSingle();

      if (familyResponse == null) {
        setState(() {
          _errorMessage = 'Família não encontrada.';
          _isLoading = false;
        });
        return;
      }

      final itemsResponse = await client
          .from('items')
          .select()
          .eq('family_id', widget.familyId)
          .eq('is_gift', true)
          .eq('gift_status', 'available')
          .order('name');

      setState(() {
        _familyData = familyResponse;
        _giftItems = List<Map<String, dynamic>>.from(itemsResponse);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar a lista de presentes.';
        _isLoading = false;
      });
    }
  }

  void _scrollToGrid() {
    Scrollable.ensureVisible(
      _gridKey.currentContext!,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _showQuickView(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => QuickViewModal(
        item: item,
        onAdd: () {
          Navigator.pop(context);
          setState(() {
            if (!_cartItems.any((i) => i['id'] == item['id'])) {
              _cartItems.add(item);
            }
          });
          _showCartModal();
        },
      ),
    );
  }

  void _showCartModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CartModal(
        cartItems: _cartItems,
        familyData: _familyData!,
        familyId: widget.familyId,
        onClose: () {
          Navigator.pop(context);
          setState(() {}); // refresh if items removed
        },
        onRemoveItem: (item) {
          setState(() {
            _cartItems.removeWhere((i) => i['id'] == item['id']);
          });
          if (_cartItems.isEmpty) {
            Navigator.pop(context);
          }
        },
        onSuccess: () {
          Navigator.pop(context);
          setState(() {
            _cartItems.clear();
          });
          _loadData(); // reload available gifts
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Muito obrigado pelo seu carinho! ❤️'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kBgColor,
        body: Center(child: CircularProgressIndicator(color: kTeal)),
      );
    }
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: kBgColor,
        body: Center(
          child: Text(
            _errorMessage,
            style: const TextStyle(fontSize: 18, color: kTextColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          // Background decorative patterns could go here
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: DotsPainter()),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  _buildHeroSection(),
                  Center(
                    key: _gridKey,
                    child: const Text(
                      'Lista de presentes',
                      style: TextStyle(
                        color: kTeal,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _giftItems.isEmpty
                      ? _buildEmptyState()
                      : _buildShoppingGrid(),
                ],
              ),
            ),
          ),
          if (_cartItems.isNotEmpty)
            Positioned(
              bottom: 20,
              right: 20,
              left: 20,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: FloatingActionButton.extended(
                    onPressed: _showCartModal,
                    backgroundColor: kTeal,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.shopping_cart),
                    label: Text(
                      'Ver Carrinho (${_cartItems.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final babyName = _familyData!['baby_name'] ?? 'Bebê';
    // Estimate weeks based on created_at or just a dummy generic 20 weeks
    int weeks = 20;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Polaroid Photo
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1516086888062-817ab087fa17?auto=format&fit=crop&q=80&w=800',
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: -15,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kTeal,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Mamãe está de',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        '$weeks',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const Text(
                        'semanas',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          const Text(
            'É tempo de alegria!',
            style: TextStyle(
              color: kTeal,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Estamos radiantes com a chegada de $babyName e queremos convidá-los a fazer parte desse momento especial.\n\nNeste espaço criado com muito amor, vamos compartilhar com vocês alguns detalhes dessa fase tão mágica.',
              style: const TextStyle(
                fontSize: 16,
                color: kTextColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _scrollToGrid,
            style: ElevatedButton.styleFrom(
              backgroundColor: kTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text(
              'VER LISTA DE PRESENTES',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildShoppingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.65,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: _giftItems.length,
          itemBuilder: (context, index) {
            final item = _giftItems[index];
            final price =
                double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
            final isPriceValid = price > 0;
            final installment = isPriceValid ? price / 6 : 0;

            return GestureDetector(
              onTap: () => _showQuickView(item),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Product Image
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        child: item['image_url'] != null
                            ? Image.network(
                                item['image_url'],
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: kLightGrey,
                                child: const Icon(
                                  Icons.card_giftcard,
                                  size: 50,
                                  color: Colors.black12,
                                ),
                              ),
                      ),
                    ),
                    // Product Details
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: kTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            Column(
                              children: [
                                if (isPriceValid) ...[
                                  Text(
                                    item['price'].toString().replaceAll(
                                      '.',
                                      ',',
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ou até 6x de ${installment.toStringAsFixed(2).replaceAll('.', ',')}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: kTeal,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ] else ...[
                                  const Text(
                                    'Valor Sugerido',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: kTeal,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (!_cartItems.any(
                                    (i) => i['id'] == item['id'],
                                  )) {
                                    _addToCart(item);
                                  } else {
                                    _showCartModal();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kTeal,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  _cartItems.any((i) => i['id'] == item['id'])
                                      ? 'no carrinho'
                                      : 'presentear',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: const [
          Icon(Icons.check_circle_outline, size: 80, color: kTeal),
          SizedBox(height: 20),
          Text(
            'Todos os presentes sugeridos já foram garantidos! A família agradece muito o carinho.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      _cartItems.add(item);
    });
    _showCartModal();
  }
}

// ---------------------------------------------------------
// QUICK VIEW MODAL
// ---------------------------------------------------------
class QuickViewModal extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onAdd;
  final String stockHint;

  const QuickViewModal({
    super.key,
    required this.item,
    required this.onAdd,
    this.stockHint = 'Resta apenas 1 unidade',
  });

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final isPriceValid = price > 0;
    final installment = isPriceValid ? price / kInstallments : 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (item['image_url'] != null)
              Image.network(item['image_url'], height: 200, fit: BoxFit.contain)
            else
              const Icon(Icons.card_giftcard, size: 100, color: Colors.black12),
            const SizedBox(height: 20),
            Text(
              item['name'],
              style: const TextStyle(
                fontSize: 18,
                color: kTextColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            if (isPriceValid) ...[
              Text(
                formatBRL(price),
                style: TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'ou até ${kInstallments}x de ${formatBRL(installment)}',
                style: const TextStyle(
                  fontSize: 18,
                  color: kTeal,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              stockHint,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'presentear',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// CART & CHECKOUT MODAL
// ---------------------------------------------------------
class CartModal extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Map<String, dynamic> familyData;
  final String familyId;
  final VoidCallback onSuccess;
  final Function(Map<String, dynamic>) onRemoveItem;
  final VoidCallback onClose;

  const CartModal({
    super.key,
    required this.cartItems,
    required this.familyData,
    required this.familyId,
    required this.onSuccess,
    required this.onRemoveItem,
    required this.onClose,
  });

  @override
  State<CartModal> createState() => _CartModalState();
}

class _CartModalState extends State<CartModal> {
  int _step = 0;
  String? _mpCheckoutUrl;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  double get _totalValue {
    double t = 0;
    for (var i in widget.cartItems) {
      t += double.tryParse(i['price']?.toString() ?? '0') ?? 0.0;
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cartItems.isEmpty) {
      return const SizedBox.shrink(); // Handled by parent
    }

    final babyName = widget.familyData['baby_name'] ?? 'Bebê';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _step == 0
                        ? 'Carrinho de compras'
                        : (_step == 1 ? 'Identificação' : 'PIX Liberado!'),
                    style: const TextStyle(
                      fontSize: 22,
                      color: kTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_step == 0) _buildCartSummary(),
              if (_step == 1) _buildCheckoutForm(babyName),
              if (_step == 2) _buildPixScreen(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: kLightGrey,
          padding: const EdgeInsets.all(10),
          child: Column(
            children: widget.cartItems.map((item) {
              final price =
                  double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      color: Colors.white,
                      child: item['image_url'] != null
                          ? Image.network(item['image_url'], fit: BoxFit.cover)
                          : const Icon(Icons.image, color: Colors.black12),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(
                              color: kTextColor,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'R\$ ${formatBRL(price)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                      ),
                      onPressed: () => widget.onRemoveItem(item),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total: R\$ ${formatBRL(_totalValue)}',
            style: const TextStyle(
              fontSize: 20,
              color: kTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onClose,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kTextColor,
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('+ presentes'),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _step = 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'pagamento',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckoutForm(String babyName) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Gostaria de deixar uma mensagem para a família do(a) $babyName?',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration('Seu Nome Completo *'),
            validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _nicknameController,
            decoration: _inputDecoration('Apelido (Opcional)'),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _phoneController,
            decoration: _inputDecoration('Seu WhatsApp (com DDD) *'),
            keyboardType: TextInputType.phone,
            validator: (v) =>
                v!.isEmpty ? 'Obrigatório para a família agradecer' : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _messageController,
            decoration: _inputDecoration('Mensagem de carinho (Opcional)'),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitContributions,
            style: ElevatedButton.styleFrom(
              backgroundColor: kTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Ir para o Pagamento',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitContributions() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final client = Supabase.instance.client;

      // Chama a Edge Function do Mercado Pago para gerar o link de pagamento
      // O banco de dados só será persistido via Webhook após aprovação do pagamento.
      final response = await client.functions.invoke(
        'create-mp-checkout',
        body: {
          'items': widget.cartItems,
          'family_id': widget.familyId,
          'giver_name': _nameController.text.trim(),
          'giver_nickname': _nicknameController.text.trim(),
          'giver_phone': _phoneController.text.trim(),
          'message_to_parents': _messageController.text.trim(),
        },
      );

      final data = response.data;
      if (data != null && data['init_point'] != null) {
        setState(() {
          _mpCheckoutUrl = data['init_point'];
          _step = 2; // Move to Checkout Link / PIX Step
          _isSubmitting = false;
        });
      } else {
        throw Exception('Resposta inválida do serviço de pagamentos');
      }
    } catch (e) {
      debugPrint('Erro no checkout: $e');
      setState(() => _isSubmitting = false);

      // Se a Edge Function falhar, exibe erro em vez de Pix
      setState(() {
        _step = 2; // Move to error display
        _isSubmitting = false;
        _mpCheckoutUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pagamento automático indisponível. Tente novamente.'),
        ),
      );
    }
  }

  Widget _buildPixScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_mpCheckoutUrl != null) ...[
          const Icon(Icons.check_circle_outline, size: 60, color: kTeal),
          const SizedBox(height: 15),
          const Text(
            'Tudo certo! O seu carrinho foi gerado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              final url = Uri.parse(_mpCheckoutUrl!);
              if (await canLaunchUrl(url)) {
                await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                  webOnlyWindowName: '_self',
                );
                // After clicking, user will be redirected. The modal can be closed on return or they click finish.
              }
            },
            icon: const Icon(Icons.payment),
            label: const Text(
              'Pagar no Mercado Pago',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009EE3), // Mercado Pago Blue
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ] else ...[
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 15),
          const Text(
            'Ocorreu um erro ao gerar o pagamento.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: kTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Tentar Novamente',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: kLightGrey,
    );
  }
}

// Custom Painter for dotted background
class DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    double spacing = 20.0;
    double radius = 1.5;

    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
