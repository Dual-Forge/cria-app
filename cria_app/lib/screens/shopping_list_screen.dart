import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Necessário para baixar o site

class ShoppingListScreen extends StatefulWidget {
  final Color currentTheme; 

  const ShoppingListScreen({super.key, required this.currentTheme});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final List<Map<String, dynamic>> _categoriesConfig = [
    {'name': 'Higiene', 'icon': Icons.bathtub, 'color': Colors.cyan},
    {'name': 'Roupas', 'icon': Icons.checkroom, 'color': Colors.orange},
    {'name': 'Quarto', 'icon': Icons.bed, 'color': Colors.indigo},
    {'name': 'Passeio', 'icon': Icons.stroller, 'color': Colors.green},
    {'name': 'Alimentação', 'icon': Icons.restaurant, 'color': Colors.amber},
    {'name': 'Mamãe', 'icon': Icons.pregnant_woman, 'color': Colors.red},
  ];

  final List<String> _ageFilters = ['Todos', 'RN', '1-3 Meses', '3-6 Meses', '6-9 Meses', '9-12 Meses', '1+ Ano'];
  String _selectedAgeFilter = 'Todos'; 
  DateTime? _dueDate; 
  late Stream<List<Map<String, dynamic>>> _itemsStream;

  @override
  void initState() {
    super.initState();
    _fetchDueDate();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _itemsStream = Supabase.instance.client.from('items').stream(primaryKey: ['id']).eq('user_id', user.id).order('created_at');
    } else {
      _itemsStream = const Stream.empty();
    }
  }

  Future<void> _fetchDueDate() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final data = await Supabase.instance.client.from('user_settings').select('due_date').eq('user_id', user.id).maybeSingle();
    if (data != null && data['due_date'] != null && mounted) {
      setState(() => _dueDate = DateTime.parse(data['due_date']));
    }
  }

  String _getCategoryTip(String category, int? weeks) {
    // ... (Mantive a lógica de dicas igual)
    if (weeks == null) return "Dica geral.";
    bool isEarly = weeks < 14; bool isMiddle = weeks >= 14 && weeks < 28;
    switch (category) {
      case 'Higiene': return isEarly ? "Pesquise marcas de fraldas." : (isMiddle ? "Estoque algodão." : "Kit higiene pronto?");
      case 'Roupas': return isEarly ? "Foque em bodies básicos." : "Cuidado com tecidos sintéticos.";
      default: return "Planeje com carinho.";
    }
  }

  // --- LÓGICA DE WEBSCRAPING SIMPLIFICADA ---
  Future<Map<String, String>> _scrapeLink(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        String html = response.body;
        String title = "";
        String image = "";
        String price = "";

        // Tenta achar OpenGraph Title
        RegExp titleRegex = RegExp(r'<meta property="og:title" content="(.*?)"');
        var matchTitle = titleRegex.firstMatch(html);
        if (matchTitle != null) title = matchTitle.group(1) ?? "";

        // Se falhar, tenta Title tag normal
        if (title.isEmpty) {
          RegExp titleTagRegex = RegExp(r'<title>(.*?)</title>');
          var matchTitleTag = titleTagRegex.firstMatch(html);
          if (matchTitleTag != null) title = matchTitleTag.group(1) ?? "";
        }

        // Tenta achar Imagem
        RegExp imageRegex = RegExp(r'<meta property="og:image" content="(.*?)"');
        var matchImage = imageRegex.firstMatch(html);
        if (matchImage != null) image = matchImage.group(1) ?? "";

        // Tenta achar Preço (Muito difícil sem API, mas tentamos achar padrão R$ XX,XX)
        // Isso é impreciso, mas melhor que nada.
        RegExp priceRegex = RegExp(r'R\$\s?(\d+([.,]\d{1,2})?)');
        var matchPrice = priceRegex.firstMatch(html);
        if (matchPrice != null) price = matchPrice.group(1) ?? "";

        return {'title': title, 'image': image, 'price': price};
      }
    } catch (e) {
      print("Erro ao ler link: $e");
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.currentTheme; 
    // ... (Cálculos mantidos iguais) ...
    int currentWeeks = 0;
    if (_dueDate != null) {
      final difference = _dueDate!.difference(DateTime.now()).inDays;
      currentWeeks = 40 - (difference / 7).floor();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _itemsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final allItemsRaw = snapshot.data!;
        final displayItems = _selectedAgeFilter == 'Todos' ? allItemsRaw : allItemsRaw.where((i) => i['age_range'] == _selectedAgeFilter).toList();
        final totalItems = displayItems.length;
        final boughtItems = displayItems.where((i) => i['is_purchased'] == true).length;
        final itemsProgress = totalItems == 0 ? 0.0 : (boughtItems / totalItems);
        final totalEstimatedCost = displayItems.fold(0.0, (sum, item) => sum + (item['price'] ?? 0.0));
        final totalSpent = displayItems.where((i) => i['is_purchased'] == true).fold(0.0, (sum, item) => sum + (item['price'] ?? 0.0));
        final financialProgress = totalEstimatedCost == 0 ? 0.0 : (totalSpent / totalEstimatedCost);

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CARD FINANCEIRO (Mantido igual)
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [themeColor.withOpacity(0.7), themeColor], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: themeColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))]),
                  child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_selectedAgeFilter == 'Todos' ? "Enxoval Completo" : "Filtro: $_selectedAgeFilter", style: const TextStyle(color: Colors.white70, fontSize: 16)), const SizedBox(height: 5), Text("${(itemsProgress * 100).toInt()}% Concluído", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))])), Stack(alignment: Alignment.center, children: [CircularPercentIndicator(radius: 35.0, lineWidth: 6.0, percent: itemsProgress, backgroundColor: Colors.white24, progressColor: Colors.white, animation: true, animateFromLastPercent: true), Icon(Icons.check, color: Colors.white.withOpacity(0.9), size: 24)])]), const SizedBox(height: 20), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Gasto: R\$ ${totalSpent.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)), Text("Total: R\$ ${totalEstimatedCost.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white70, fontSize: 12))]), const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: financialProgress, backgroundColor: Colors.white24, color: Colors.white, minHeight: 8))]))]),
                ),

                const SizedBox(height: 20),
                // FILTROS (Mantido igual)
                SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _ageFilters.map((filter) { final isSelected = _selectedAgeFilter == filter; return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(filter), selected: isSelected, onSelected: (bool selected) => setState(() => _selectedAgeFilter = selected ? filter : 'Todos'), selectedColor: themeColor.withOpacity(0.2), labelStyle: TextStyle(color: isSelected ? themeColor : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? themeColor : Colors.grey.shade300)))); }).toList())),
                
                const SizedBox(height: 25),
                const Text("Resumo de Gastos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildFinancialChart(displayItems),

                const SizedBox(height: 25),
                const Text("Categorias", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.95), itemCount: _categoriesConfig.length, itemBuilder: (context, index) { final catConfig = _categoriesConfig[index]; final catName = catConfig['name']; final catItems = displayItems.where((i) => i['category'] == catName).toList(); final catTotal = catItems.length; final catBought = catItems.where((i) => i['is_purchased'] == true).length; final catProgress = catTotal == 0 ? 0.0 : (catBought / catTotal); final tip = _getCategoryTip(catName, currentWeeks); return _buildCategoryCard(context, catConfig, catTotal, catBought, catProgress, tip); }),
              ],
            ),
          ),
          // BOTÃO NOVO ITEM (Chama a nova Sheet)
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddItemSheet(context, _categoriesConfig[0]['name']),
            label: const Text("Novo Item"),
            icon: const Icon(Icons.add),
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  // --- NOVA INTERFACE DE CADASTRO (BOTTOM SHEET) ---
  void _showAddItemSheet(BuildContext context, String initialCategory) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final noteController = TextEditingController();
    final linkController = TextEditingController(); // Controlador do Link
    
    String selectedCategory = initialCategory;
    String? selectedAge;
    List<String> categories = _categoriesConfig.map((e) => e['name'] as String).toList();
    List<String> agesForSelect = _ageFilters.where((a) => a != 'Todos').toList();
    File? imageFile;
    String? scrapedImageUrl; // URL da imagem do site
    bool isUploading = false;
    bool isScraping = false; // Loading do link

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite tela cheia e teclado não cobrir
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            
            // Função para pegar dados do link
            Future<void> autoFillFromLink() async {
              if (linkController.text.isEmpty) return;
              setStateSheet(() => isScraping = true);
              
              final data = await _scrapeLink(linkController.text);
              
              if (data.isNotEmpty) {
                if (data['title']!.isNotEmpty) nameController.text = data['title']!;
                if (data['price']!.isNotEmpty) priceController.text = data['price']!;
                if (data['image']!.isNotEmpty) scrapedImageUrl = data['image'];
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Não conseguimos ler este site automaticamente. Tente preencher.")));
              }
              setStateSheet(() => isScraping = false);
            }

            Future<void> pickImage(ImageSource source) async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: source, imageQuality: 50);
              if (picked != null) setStateSheet(() => imageFile = File(picked.path));
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, controller) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
                  child: ListView(
                    controller: controller,
                    children: [
                      Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 20),
                      Text("Novo Item", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: widget.currentTheme)),
                      const SizedBox(height: 20),

                      // --- ÁREA DO LINK INTELIGENTE ---
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: widget.currentTheme.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: widget.currentTheme.withOpacity(0.3))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Possui o link da loja?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Row(
                              children: [
                                Expanded(child: TextField(controller: linkController, decoration: const InputDecoration(hintText: "Cole o link aqui (Amazon, Shopee...)", border: InputBorder.none, isDense: true))),
                                if (isScraping) 
                                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                else
                                  IconButton(icon: const Icon(Icons.auto_awesome, color: Colors.amber), onPressed: autoFillFromLink, tooltip: "Preencher Automático"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(controller: nameController, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: "Nome do Produto", border: OutlineInputBorder())),
                      const SizedBox(height: 15),
                      
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(value: selectedCategory, decoration: const InputDecoration(labelText: "Categoria", border: OutlineInputBorder()), items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setStateSheet(() => selectedCategory = v!)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Valor (R\$)", border: OutlineInputBorder())),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      DropdownButtonFormField<String>(value: selectedAge, decoration: const InputDecoration(labelText: "Faixa Etária (Opcional)", border: OutlineInputBorder()), items: agesForSelect.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setStateSheet(() => selectedAge = v), hint: const Text("Selecione se quiser")),
                      const SizedBox(height: 15),
                      
                      TextField(controller: noteController, maxLines: 2, decoration: const InputDecoration(labelText: "Observações", border: OutlineInputBorder())),
                      
                      const SizedBox(height: 20),
                      const Text("Foto", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      
                      // PREVIEW DA FOTO (Local ou do Site)
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => pickImage(ImageSource.gallery),
                            child: Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                              child: imageFile != null 
                                  ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(imageFile!, fit: BoxFit.cover))
                                  : (scrapedImageUrl != null && scrapedImageUrl!.isNotEmpty 
                                      ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(scrapedImageUrl!, fit: BoxFit.cover))
                                      : const Icon(Icons.add_a_photo, color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 15),
                          if (imageFile == null && scrapedImageUrl == null)
                            const Text("Toque para adicionar foto", style: TextStyle(color: Colors.grey))
                          else 
                            TextButton(onPressed: () => setStateSheet((){ imageFile = null; scrapedImageUrl = null; }), child: const Text("Remover Foto", style: TextStyle(color: Colors.red)))
                        ],
                      ),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: widget.currentTheme, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          onPressed: isUploading ? null : () async {
                            if (nameController.text.isNotEmpty) {
                              setStateSheet(() => isUploading = true);
                              final user = Supabase.instance.client.auth.currentUser;
                              String? finalImageUrl = scrapedImageUrl; // Começa com a do site

                              // Se tiver foto local, faz upload e substitui
                              if (imageFile != null) {
                                try {
                                  final fileName = '${user!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                                  await Supabase.instance.client.storage.from('product_photos').upload(fileName, imageFile!);
                                  finalImageUrl = Supabase.instance.client.storage.from('product_photos').getPublicUrl(fileName);
                                } catch (e) { print("Erro upload: $e"); }
                              }

                              double price = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
                              
                              await Supabase.instance.client.from('items').insert({
                                'user_id': user!.id,
                                'name': nameController.text,
                                'price': price,
                                'notes': noteController.text,
                                'link_url': linkController.text,
                                'image_url': finalImageUrl,
                                'category': selectedCategory,
                                'age_range': selectedAge ?? 'Geral',
                                'is_purchased': false
                              });
                              
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          child: isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text("Salvar Item", style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- MÉTODOS AUXILIARES DE VISUALIZAÇÃO ---
  Widget _buildFinancialChart(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const Text("Adicione itens com valores para ver o gráfico.");
    return Column(children: _categoriesConfig.map((cat) { final catItems = items.where((i) => i['category'] == cat['name']).toList(); if (catItems.isEmpty) return const SizedBox.shrink(); final totalCat = catItems.fold(0.0, (sum, item) => sum + (item['price'] ?? 0.0)); final spentCat = catItems.where((i) => i['is_purchased'] == true).fold(0.0, (sum, item) => sum + (item['price'] ?? 0.0)); final percent = totalCat == 0 ? 0.0 : (spentCat / totalCat); return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(cat['icon'], size: 16, color: cat['color']), const SizedBox(width: 5), Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]), Text("R\$ ${spentCat.toStringAsFixed(0)} / R\$ ${totalCat.toStringAsFixed(0)}", style: TextStyle(color: Colors.grey[600], fontSize: 12))]), const SizedBox(height: 5), Stack(children: [Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))), FractionallySizedBox(widthFactor: percent.clamp(0.0, 1.0), child: Container(height: 8, decoration: BoxDecoration(color: cat['color'], borderRadius: BorderRadius.circular(4))))])])); }).toList());
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> config, int total, int bought, double progress, String tip) {
    return InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryDetailScreen(category: config['name'], ageFilter: _selectedAgeFilter, themeColor: widget.currentTheme))), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 3))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: config['color'].withOpacity(0.1), shape: BoxShape.circle), child: Icon(config['icon'], color: config['color'], size: 20)), Text("${(progress * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: config['color'], fontSize: 12))]), const SizedBox(height: 8), GestureDetector(onTap: () => _showTipDialog(context, config['name'], tip), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.lightbulb, size: 12, color: Colors.amber), const SizedBox(width: 6), Expanded(child: Text(tip, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Colors.grey[700], height: 1.1)))])))]), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(config['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text("$bought / $total itens", style: TextStyle(color: Colors.grey[400], fontSize: 11)), const SizedBox(height: 6), LinearProgressIndicator(value: progress, backgroundColor: config['color'].withOpacity(0.1), color: config['color'], minHeight: 4, borderRadius: BorderRadius.circular(2))])])));
  }

  void _showTipDialog(BuildContext context, String title, String tip) { showDialog(context: context, builder: (ctx) => AlertDialog(title: Row(children: [const Icon(Icons.lightbulb, color: Colors.amber), const SizedBox(width: 10), Text(title)]), content: Text(tip), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Entendi"))])); }
}

class CategoryDetailScreen extends StatelessWidget {
  final String category; final String ageFilter; final Color themeColor;
  const CategoryDetailScreen({super.key, required this.category, required this.ageFilter, required this.themeColor});
  Future<void> _toggleItem(String itemId, bool val) async { await Supabase.instance.client.from('items').update({'is_purchased': !val}).eq('id', itemId); }
  Future<void> _deleteItem(BuildContext context, String itemId) async { await Supabase.instance.client.from('items').delete().eq('id', itemId); if(context.mounted) Navigator.pop(context); }
  Future<void> _launchURL(BuildContext context, String? url) async { if (url != null && await canLaunchUrl(Uri.parse(url))) { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link inválido"))); } }
  void _openItemDetails(BuildContext context, Map<String, dynamic> item) { showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return DraggableScrollableSheet(initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.95, expand: false, builder: (_, controller) { return SingleChildScrollView(controller: controller, padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 20), if (item['image_url'] != null && item['image_url'].toString().isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(item['image_url'], height: 250, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(height: 150, color: Colors.grey[200], child: const Icon(Icons.broken_image)))) else Center(child: Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[200])), const SizedBox(height: 20), Text(item['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(item['age_range'] ?? 'Geral', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold))), const Spacer(), Text(item['price'] != null ? "R\$ ${item['price']}" : "R\$ --", style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold))]), const Divider(height: 30), const Text("Observações:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 5), Text((item['notes'] != null && item['notes'].toString().isNotEmpty) ? item['notes'] : "Nenhuma anotação.", style: const TextStyle(fontSize: 16)), const SizedBox(height: 30), SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: (item['link_url'] != null && item['link_url'].toString().isNotEmpty) ? () => _launchURL(context, item['link_url']) : null, style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white), icon: const Icon(Icons.link), label: const Text("Ir para a Loja"))), const SizedBox(height: 10), Center(child: TextButton.icon(onPressed: () => _deleteItem(context, item['id']), icon: const Icon(Icons.delete_outline, color: Colors.red), label: const Text("Excluir Item", style: TextStyle(color: Colors.red))))]));});}); }
  @override
  Widget build(BuildContext context) { final user = Supabase.instance.client.auth.currentUser; return Scaffold(backgroundColor: Colors.grey[50], appBar: AppBar(title: Text("$category ${ageFilter != 'Todos' ? '($ageFilter)' : ''}"), backgroundColor: themeColor, foregroundColor: Colors.white, elevation: 0), body: StreamBuilder<List<Map<String, dynamic>>>(stream: Supabase.instance.client.from('items').stream(primaryKey: ['id']).eq('user_id', user!.id).order('created_at').map((items) { var filtered = items.where((i) => i['category'] == category); if (ageFilter != 'Todos') { filtered = filtered.where((i) => i['age_range'] == ageFilter); } return filtered.toList(); }), builder: (context, snapshot) { if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); final items = snapshot.data!; if (items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.playlist_add, size: 60, color: Colors.grey[300]), const SizedBox(height: 10), Text("Nenhum item encontrado.", style: TextStyle(color: Colors.grey[600]))])); final total = items.length; final bought = items.where((i) => i['is_purchased'] == true).length; final progress = total == 0 ? 0.0 : bought / total; return Column(children: [Container(padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Progresso em $category", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)), Text("${(progress * 100).toInt()}%", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold))]), const SizedBox(height: 10), LinearPercentIndicator(lineHeight: 12.0, percent: progress, backgroundColor: themeColor.withOpacity(0.1), progressColor: themeColor, barRadius: const Radius.circular(10), animation: true, animateFromLastPercent: true)])), Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (context, index) { final item = items[index]; final isPurchased = item['is_purchased'] ?? false; return GestureDetector(onTap: () => _openItemDetails(context, item), child: Card(margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 2, color: isPurchased ? Colors.grey[100] : Colors.white, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (item['image_url'] != null) ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), child: ColorFiltered(colorFilter: isPurchased ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : const ColorFilter.mode(Colors.transparent, BlendMode.multiply), child: Image.network(item['image_url'], height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(height: 150, color: Colors.grey[200], child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)))))), Padding(padding: const EdgeInsets.all(12), child: Row(children: [Transform.scale(scale: 1.3, child: Checkbox(value: isPurchased, activeColor: themeColor, shape: const CircleBorder(), onChanged: (val) => _toggleItem(item['id'], isPurchased))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: isPurchased ? TextDecoration.lineThrough : null, color: isPurchased ? Colors.grey : Colors.black87)), if (item['price'] != null) Text("R\$ ${item['price']}", style: TextStyle(color: isPurchased ? Colors.grey : Colors.green, fontWeight: FontWeight.bold))]))]))]))); }))]);},),);
  }
}