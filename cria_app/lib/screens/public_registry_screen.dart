import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class PublicRegistryScreen extends StatefulWidget {
  final String familyId;

  const PublicRegistryScreen({super.key, required this.familyId});

  @override
  State<PublicRegistryScreen> createState() => _PublicRegistryScreenState();
}

class _PublicRegistryScreenState extends State<PublicRegistryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _gifts = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableGifts();
  }

  Future<void> _loadAvailableGifts() async {
    try {
      // Busca apenas os itens que os pais marcaram como presente (is_gift = true)
      // e que ainda não foram comprados (is_purchased = false)
      final response = await Supabase.instance.client
          .from('items')
          .select()
          .eq('family_id', widget.familyId)
          .eq('is_gift', true)
          .eq('is_purchased', false)
          .order('price', ascending: true);

      if (mounted) {
        setState(() {
          _gifts = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar presentes: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Lista de Presentes'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _gifts.isEmpty
          ? _buildEmptyState()
          : _buildGiftsGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'Nenhum presente disponível no momento.',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65, // Ajusta a altura do card
      ),
      itemCount: _gifts.length,
      itemBuilder: (context, index) {
        final gift = _gifts[index];
        final imageUrl = gift['image_url']?.toString();
        final price = gift['price'] ?? 0.0;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagem do Produto
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.shopping_bag,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
              ),
              // Detalhes
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      gift['name'] ?? 'Presente',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'R\$ $price',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // BOTÃO MÁGICO QUE RESOLVE O ERRO 400
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // Navega para o Checkout passando o item escolhido!
                          context.push(
                            '/checkout/${widget.familyId}',
                            extra: [
                              gift,
                            ], // O selectedItems não será mais vazio!
                          );
                        },
                        child: const Text('Presentear'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
