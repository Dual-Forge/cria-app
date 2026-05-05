// import 'dart:io'; // Removed for Web compatibility
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:http/http.dart' as http;

class ShoppingListScreen extends StatefulWidget {
  final Color currentTheme;
  final String? familyId;

  const ShoppingListScreen({
    super.key,
    required this.currentTheme,
    this.familyId,
  });

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

  final List<String> _ageFilters = [
    'Todos',
    'RN',
    '1-3 Meses',
    '3-6 Meses',
    '6-9 Meses',
    '9-12 Meses',
    '1+ Ano',
  ];
  String _selectedAgeFilter = 'Todos';
  DateTime? _dueDate;
  late Stream<List<Map<String, dynamic>>> _itemsStream;

  @override
  void initState() {
    super.initState();
    _fetchDueDate();

    // Configura o stream corretamente para atualizar em tempo real
    final client = Supabase.instance.client;
    if (widget.familyId != null) {
      _itemsStream = client
          .from('items')
          .stream(primaryKey: ['id'])
          .eq('family_id', widget.familyId!)
          .order('created_at');
    } else {
      final user = client.auth.currentUser;
      if (user != null) {
        _itemsStream = client
            .from('items')
            .stream(primaryKey: ['id'])
            .eq('user_id', user.id)
            .order('created_at');
      } else {
        _itemsStream = const Stream.empty();
      }
    }
  }

  Future<void> _fetchDueDate() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final data = await Supabase.instance.client
          .from('user_settings')
          .select('due_date')
          .eq('user_id', user.id)
          .maybeSingle();
      if (data != null && data['due_date'] != null && mounted) {
        setState(() => _dueDate = DateTime.parse(data['due_date']));
      }
    } catch (e) {
      /* Silencia erro se config não existir */
    }
  }

  String _getCategoryTip(String category, int? weeks) {
    if (weeks == null) return "Dica geral.";
    bool isEarly = weeks < 14;
    bool isMiddle = weeks >= 14 && weeks < 28;
    switch (category) {
      case 'Higiene':
        return isEarly
            ? "Pesquise marcas de fraldas."
            : (isMiddle ? "Estoque algodão." : "Kit higiene pronto?");
      case 'Roupas':
        return isEarly
            ? "Foque em bodies básicos."
            : "Cuidado com tecidos sintéticos.";
      default:
        return "Planeje com carinho.";
    }
  }

  // --- CORREÇÃO 1: CARREGAMENTO AUTOMÁTICO (Scraping) ---
  Future<Map<String, String>> _scrapeLink(String url) async {
    if (kIsWeb) return {}; // Disable scraping on Web to prevent CORS crashes
    try {
      final uri = Uri.parse(url);

      // Adicionamos Headers para simular um navegador real (evita bloqueios da Amazon/Shopee)
      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            },
          )
          .timeout(const Duration(seconds: 8)); // Aumentei um pouco o tempo

      if (response.statusCode == 200) {
        String html = response.body;
        String title = "";
        String image = "";
        String price = "";

        // Tenta pegar o Título
        RegExp titleRegex = RegExp(
          r'<meta property="og:title" content="(.*?)"',
        );
        var matchTitle = titleRegex.firstMatch(html);
        if (matchTitle != null) title = matchTitle.group(1) ?? "";
        if (title.isEmpty) {
          RegExp titleTag = RegExp(r'<title>(.*?)</title>');
          var matchTag = titleTag.firstMatch(html);
          if (matchTag != null) title = matchTag.group(1) ?? "";
        }

        // Tenta pegar a Imagem
        RegExp imageRegex = RegExp(
          r'<meta property="og:image" content="(.*?)"',
        );
        var matchImage = imageRegex.firstMatch(html);
        if (matchImage != null) image = matchImage.group(1) ?? "";

        // Tenta pegar o Preço (Procura por R$ XX,XX)
        RegExp priceRegex = RegExp(r'R\$\s?(\d+([.,]\d{1,2})?)');
        var matchPrice = priceRegex.firstMatch(html);
        if (matchPrice != null) price = matchPrice.group(1) ?? "";

        return {'title': title, 'image': image, 'price': price};
      }
    } catch (e) {
      print("Erro ao ler site: $e");
    }
    return {};
  }

  // --- CORREÇÃO 2: CHECKBOX E ATUALIZAÇÃO ---

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.currentTheme;
    int currentWeeks = 0;
    if (_dueDate != null) {
      final diff = _dueDate!.difference(DateTime.now()).inDays;
      currentWeeks = 40 - (diff / 7).floor();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _itemsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allItemsRaw = snapshot.data!;

        // Filtra por idade
        final displayItems = _selectedAgeFilter == 'Todos'
            ? allItemsRaw
            : allItemsRaw
                  .where((i) => i['age_range'] == _selectedAgeFilter)
                  .toList();

        // --- CORREÇÃO 3: CÁLCULOS ROBUSTOS ---
        // Garante que o valor venha como número, mesmo se estiver salvo estranho no banco
        final totalItems = displayItems.length;
        final boughtItems = displayItems
            .where((i) => i['is_purchased'] == true)
            .length;

        // Previne divisão por zero
        final itemsProgress = totalItems == 0
            ? 0.0
            : (boughtItems / totalItems);

        double totalEstimatedCost = 0.0;
        double totalSpent = 0.0;

        for (var item in displayItems) {
          // Converte o preço com segurança
          double price = (item['price'] as num?)?.toDouble() ?? 0.0;

          totalEstimatedCost += price;

          // Se estiver comprado (checkbox marcado), soma nos gastos
          if (item['is_purchased'] == true) {
            totalSpent += price;
          }
        }

        final financialProgress = totalEstimatedCost == 0
            ? 0.0
            : (totalSpent / totalEstimatedCost);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CARD FINANCEIRO
                Container(
                  padding: const EdgeInsets.only(
                    top: 60,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Seu Enxoval",
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _selectedAgeFilter == 'Todos'
                                    ? "Progresso Geral"
                                    : "Filtro: $_selectedAgeFilter",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          CircularPercentIndicator(
                            radius: 40.0,
                            lineWidth: 8.0,
                            percent: itemsProgress,
                            backgroundColor: Colors.grey[100]!,
                            progressColor: themeColor,
                            circularStrokeCap: CircularStrokeCap.round,
                            animation: true,
                            center: Text(
                              "${(itemsProgress * 100).toInt()}%",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: themeColor.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.attach_money,
                                color: themeColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Investimento Total",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "R\$ ${totalSpent.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      color: Colors.grey[900],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: financialProgress.clamp(0.0, 1.0),
                                      backgroundColor: Colors.white,
                                      color: themeColor,
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "de R\$ ${totalEstimatedCost.toStringAsFixed(2)} planejado",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // FILTROS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _ageFilters.map((filter) {
                      final isSelected = _selectedAgeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (bool selected) => setState(
                            () => _selectedAgeFilter = selected
                                ? filter
                                : 'Todos',
                          ),
                          selectedColor: themeColor.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? themeColor : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? themeColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 25),
                const Text(
                  "Resumo de Gastos",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _buildFinancialChart(displayItems),

                const SizedBox(height: 25),
                const Text(
                  "Categorias",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: _categoriesConfig.length,
                  itemBuilder: (context, index) {
                    final catConfig = _categoriesConfig[index];
                    final catName = catConfig['name'];
                    final catItems = displayItems
                        .where((i) => i['category'] == catName)
                        .toList();
                    final catTotal = catItems.length;
                    final catBought = catItems
                        .where((i) => i['is_purchased'] == true)
                        .length;
                    final catProgress = catTotal == 0
                        ? 0.0
                        : (catBought / catTotal);
                    final tip = _getCategoryTip(catName, currentWeeks);
                    return _buildCategoryCard(
                      context,
                      catConfig,
                      catTotal,
                      catBought,
                      catProgress,
                      tip,
                    );
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                _showAddItemSheet(context, _categoriesConfig[0]['name']),
            label: const Text("Novo Item"),
            icon: const Icon(Icons.add),
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  void _showAddItemSheet(
    BuildContext context,
    String initialCategory, {
    Map<String, dynamic>? itemToEdit,
  }) {
    final nameController = TextEditingController(text: itemToEdit?['name']);
    final priceController = TextEditingController(
      text: itemToEdit?['price']?.toString(),
    );
    final noteController = TextEditingController(text: itemToEdit?['notes']);
    final linkController = TextEditingController(text: itemToEdit?['link_url']);

    String selectedCategory = itemToEdit?['category'] ?? initialCategory;
    String? selectedAge = itemToEdit?['age_range'];

    // Ensure selectedCategory is valid
    if (!_categoriesConfig.any((c) => c['name'] == selectedCategory)) {
      selectedCategory = _categoriesConfig[0]['name'];
    }

    List<String> categories = _categoriesConfig
        .map((e) => e['name'] as String)
        .toList();
    List<String> agesForSelect = _ageFilters
        .where((a) => a != 'Todos')
        .toList();

    // Safety check: Ensure selectedCategory exists in the list
    if (!categories.contains(selectedCategory)) {
      selectedCategory = categories.isNotEmpty ? categories[0] : 'Higiene';
    }

    // Safety check: Ensure selectedAge exists in the list or is null
    if (selectedAge != null && !agesForSelect.contains(selectedAge)) {
      selectedAge = null;
    }

    // XFile? imageFile; // Removed unused
    Uint8List? imageBytes;
    String? scrapedImageUrl = itemToEdit?['image_url'];
    bool isUploading = false;
    bool isScraping = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            Future<void> autoFillFromLink() async {
              if (linkController.text.isEmpty) return;
              setStateSheet(() => isScraping = true);
              final data = await _scrapeLink(linkController.text);
              if (data.isNotEmpty) {
                if (data['title']!.isNotEmpty) {
                  nameController.text = data['title']!;
                }
                if (data['price']!.isNotEmpty) {
                  priceController.text = data['price']!;
                }
                if (data['image']!.isNotEmpty) scrapedImageUrl = data['image'];
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Não foi possível ler o site. Tente preencher manualmente.",
                    ),
                  ),
                );
              }
              setStateSheet(() => isScraping = false);
            }

            Future<void> pickImage(ImageSource source) async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: source,
                imageQuality: 50,
              );
              if (picked != null) {
                final bytes = await picked.readAsBytes();
                setStateSheet(() {
                  // imageFile = picked;
                  imageBytes = bytes;
                });
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: ScrollController(),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        12,
                        24,
                        MediaQuery.of(context).viewInsets.bottom + 24,
                      ),
                      children: [
                        /*
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      */
                        const SizedBox(height: 20),
                        Text(
                          itemToEdit != null ? "Editar Item" : "Novo Item",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: widget.currentTheme,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.currentTheme.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: widget.currentTheme.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Possui o link da loja?",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: linkController,
                                      decoration: const InputDecoration(
                                        hintText: "Cole o link aqui...",
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  if (isScraping)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    IconButton(
                                      icon: const Icon(
                                        Icons.auto_awesome,
                                        color: Colors.amber,
                                      ),
                                      onPressed: autoFillFromLink,
                                      tooltip: "Preencher Automático",
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: "Nome do Produto",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: "Categoria",
                                  border: OutlineInputBorder(),
                                ),
                                items: categories
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setStateSheet(() => selectedCategory = v!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Valor (R\$)",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          initialValue: selectedAge,
                          decoration: const InputDecoration(
                            labelText: "Faixa Etária (Opcional)",
                            border: OutlineInputBorder(),
                          ),
                          items: agesForSelect
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setStateSheet(() => selectedAge = v),
                          hint: const Text("Selecione se quiser"),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: noteController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: "Observações",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Foto",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => pickImage(ImageSource.gallery),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: (imageBytes != null)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.memory(
                                          imageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : (scrapedImageUrl != null &&
                                            scrapedImageUrl!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              scrapedImageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Center(
                                                child: Icon(Icons.broken_image,
                                                    color: Colors.grey),
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.add_a_photo,
                                            color: Colors.grey,
                                          )),
                              ),
                            ),
                            const SizedBox(width: 15),
                            if (imageBytes == null && scrapedImageUrl == null)
                              const Text(
                                "Toque para adicionar foto",
                                style: TextStyle(color: Colors.grey),
                              )
                            else
                              TextButton(
                                onPressed: () => setStateSheet(() {
                                  // imageFile = null;
                                  imageBytes = null;
                                  scrapedImageUrl = null;
                                }),
                                child: const Text(
                                  "Remover Foto",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.currentTheme,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: isUploading
                                ? null
                                : () async {
                                    if (nameController.text.isNotEmpty) {
                                      setStateSheet(() => isUploading = true);
                                      try {
                                        final user = Supabase
                                            .instance
                                            .client
                                            .auth
                                            .currentUser;
                                        String? finalImageUrl = scrapedImageUrl;

                                        if (imageBytes != null) {
                                          final fileName =
                                              'product_photos/${user!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

                                          await Supabase.instance.client.storage
                                              .from('product_photos')
                                              .uploadBinary(
                                                fileName,
                                                imageBytes!,
                                                fileOptions: const FileOptions(
                                                  contentType: 'image/jpeg',
                                                ),
                                              );
                                          finalImageUrl = Supabase
                                              .instance
                                              .client
                                              .storage
                                              .from('product_photos')
                                              .getPublicUrl(fileName);
                                        }

                                        double price =
                                            double.tryParse(
                                              priceController.text.replaceAll(
                                                ',',
                                                '.',
                                              ),
                                            ) ??
                                            0.0;

                                        if (itemToEdit != null) {
                                          // Update existing
                                          await Supabase.instance.client
                                              .from('items')
                                              .update({
                                                'name': nameController.text,
                                                'price': price,
                                                'notes': noteController.text,
                                                'link_url': linkController.text,
                                                'image_url': finalImageUrl,
                                                'category': selectedCategory,
                                                'age_range':
                                                    selectedAge ?? 'Geral',
                                              })
                                              .eq('id', itemToEdit['id']);
                                        } else {
                                          // Insert new
                                          await Supabase.instance.client
                                              .from('items')
                                              .insert({
                                                'user_id': user!.id,
                                                'family_id': widget.familyId,
                                                'name': nameController.text,
                                                'price': price,
                                                'notes': noteController.text,
                                                'link_url': linkController.text,
                                                'image_url': finalImageUrl,
                                                'category': selectedCategory,
                                                'age_range':
                                                    selectedAge ?? 'Geral',
                                                'is_purchased': false,
                                              });
                                        }

                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        setStateSheet(
                                          () => isUploading = false,
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text("Erro ao salvar: $e"),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: isUploading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    itemToEdit != null
                                        ? "Atualizar Item"
                                        : "Salvar Item",
                                    style: const TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFinancialChart(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Text("Adicione itens com valores para ver o gráfico.");
    }
    return Column(
      children: _categoriesConfig.map((cat) {
        final catItems = items
            .where((i) => i['category'] == cat['name'])
            .toList();
        if (catItems.isEmpty) return const SizedBox.shrink();
        final totalCat = catItems.fold(
          0.0,
          (sum, item) => sum + ((item['price'] as num?)?.toDouble() ?? 0.0),
        );
        final spentCat = catItems
            .where((i) => i['is_purchased'] == true)
            .fold(
              0.0,
              (sum, item) => sum + ((item['price'] as num?)?.toDouble() ?? 0.0),
            );
        final percent = totalCat == 0 ? 0.0 : (spentCat / totalCat);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(cat['icon'], size: 16, color: cat['color']),
                      const SizedBox(width: 5),
                      Text(
                        cat['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "R\$ ${spentCat.toStringAsFixed(0)} / R\$ ${totalCat.toStringAsFixed(0)}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: percent.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: cat['color'],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Map<String, dynamic> config,
    int total,
    int bought,
    double progress,
    String tip,
  ) {
    // Premium Color Palette integration
    final Color baseColor = config['color'];
    final bool isCompleted = progress >= 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryDetailScreen(
            category: config['name'],
            ageFilter: _selectedAgeFilter,
            themeColor: widget.currentTheme,
            familyId: widget.familyId,
            onEditItem: (ctx, cat, {itemToEdit}) =>
                _showAddItemSheet(ctx, cat, itemToEdit: itemToEdit),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isCompleted
                ? baseColor.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(config['icon'], color: baseColor, size: 26),
                ),
                // Percentage Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted ? baseColor : Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompleted
                          ? Colors.transparent
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    "${(progress * 100).toInt()}%",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? Colors.white : Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Colors.blueGrey[900],
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      "$bought",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: baseColor,
                      ),
                    ),
                    Text(
                      " / $total itens",
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Premium Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [baseColor.withOpacity(0.7), baseColor],
                          ),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: baseColor.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryDetailScreen extends StatefulWidget {
  final String category;
  final String ageFilter;
  final Color themeColor;
  final String? familyId;
  final Function(BuildContext, String, {Map<String, dynamic>? itemToEdit})
  onEditItem;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.ageFilter,
    required this.themeColor,
    required this.onEditItem,
    this.familyId,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late Stream<List<Map<String, dynamic>>> _itemsStream;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    var query = client.from('items').stream(primaryKey: ['id']);

    if (widget.familyId != null) {
      _itemsStream = query.eq('family_id', widget.familyId!);
    } else {
      final user = client.auth.currentUser;
      if (user != null) {
        _itemsStream = query.eq('user_id', user.id);
      } else {
        _itemsStream = const Stream.empty();
      }
    }

    // Optimize Stream: Sort and filter inside the stream definition if possible,
    // or wrap it here to avoid re-creating transform on every build.
    _itemsStream = _itemsStream.map((items) {
      items.sort(
        (a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''),
      );
      return items;
    });
  }

  Future<void> _toggleItem(String itemId, bool val) async {
    try {
      await Supabase.instance.client
          .from('items')
          .update({'is_purchased': !val})
          .eq('id', itemId);
    } catch (e) {
      debugPrint('Error toggling item: $e');
    }
  }

  Future<void> _toggleGiftStatus(String itemId, bool currentStatus) async {
    try {
      await Supabase.instance.client
          .from('items')
          .update({'is_gift': !currentStatus})
          .eq('id', itemId);

      if (mounted && !currentStatus) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item adicionado à lista pública de presentes! 🎁'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling gift status: $e');
    }
  }

  Future<void> _deleteItem(BuildContext context, String itemId) async {
    try {
      await Supabase.instance.client.from('items').delete().eq('id', itemId);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error deleting item: $e');
    }
  }

  Future<void> _launchURL(BuildContext context, String? url) async {
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Link inválido")));
      }
    }
  }

  void _openItemDetails(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item['image_url'] != null &&
                          item['image_url'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            item['image_url'],
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            cacheWidth: 600, // Optimize memory
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image),
                                ),
                          ),
                        )
                      else
                        Center(
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: 80,
                            color: Colors.grey[200],
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        item['name'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: widget.themeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['age_range'] ?? 'Geral',
                              style: TextStyle(
                                color: widget.themeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item['price'] != null
                                ? "R\$ ${item['price']}"
                                : "R\$ --",
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      const Text(
                        "Observações:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        (item['notes'] != null &&
                                item['notes'].toString().isNotEmpty)
                            ? item['notes']
                            : "Nenhuma anotação.",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed:
                              (item['link_url'] != null &&
                                  item['link_url'].toString().isNotEmpty)
                              ? () => _launchURL(context, item['link_url'])
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.themeColor,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.link),
                          label: const Text("Ir para a Loja"),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => _deleteItem(context, item['id']),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          label: const Text(
                            "Excluir Item",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // BOTÃO EDITAR
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Close details
                            widget.onEditItem(
                              context,
                              widget.category,
                              itemToEdit: item,
                            );
                          },
                          icon: Icon(Icons.edit, color: widget.themeColor),
                          label: Text(
                            "Editar Item",
                            style: TextStyle(color: widget.themeColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "${widget.category} ${widget.ageFilter != 'Todos' ? '(${widget.ageFilter})' : ''}",
        ),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _itemsStream.map((items) {
          var filtered = items.where((i) => i['category'] == widget.category);
          if (widget.ageFilter != 'Todos') {
            filtered = filtered.where(
              (i) => i['age_range'] == widget.ageFilter,
            );
          }
          return filtered.toList();
        }),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_add, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text(
                    "Nenhum item encontrado.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          final total = items.length;
          final bought = items.where((i) => i['is_purchased'] == true).length;
          final progress = total == 0 ? 0.0 : bought / total;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Progresso em ${widget.category}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${(progress * 100).toInt()}%",
                          style: TextStyle(
                            color: widget.themeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearPercentIndicator(
                      lineHeight: 12.0,
                      percent: progress.clamp(0.0, 1.0),
                      backgroundColor: widget.themeColor.withOpacity(0.1),
                      progressColor: widget.themeColor,
                      barRadius: const Radius.circular(10),
                      animation: true,
                      animateFromLastPercent: true,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isPurchased = item['is_purchased'] ?? false;

                    return GestureDetector(
                      onTap: () => _openItemDetails(context, item),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isPurchased ? Colors.grey[50] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isPurchased
                              ? Border.all(color: Colors.grey.shade200)
                              : Border.all(color: Colors.transparent),
                          boxShadow: isPurchased
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            // 1. Imagem Principal
                            Hero(
                              tag: 'item_${item['id']}',
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[100],
                                ),
                                child: item['image_url'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: ColorFiltered(
                                          colorFilter: isPurchased
                                              ? const ColorFilter.mode(
                                                  Colors.grey,
                                                  BlendMode.saturation,
                                                )
                                              : const ColorFilter.mode(
                                                  Colors.transparent,
                                                  BlendMode.multiply,
                                                ),
                                          child: Image.network(
                                            item['image_url'],
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            cacheWidth: 200,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                Icon(
                                              Icons.shopping_bag_outlined,
                                              color: Colors.grey[400],
                                              size: 30,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.shopping_bag_outlined,
                                        color: Colors.grey[400],
                                        size: 30,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 15),

                            // 2. Detalhes
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isPurchased
                                          ? Colors.grey[500]
                                          : Colors.grey[800],
                                      decoration: isPurchased
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (item['age_range'] != null &&
                                          item['age_range'] != 'Todos')
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isPurchased
                                                ? Colors.grey[200]
                                                : widget.themeColor.withOpacity(
                                                    0.1,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            item['age_range'],
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isPurchased
                                                  ? Colors.grey[600]
                                                  : widget.themeColor,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        item['price'] != null
                                            ? "R\$ ${item['price']}"
                                            : "Preço não def.",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isPurchased
                                              ? Colors.grey[400]
                                              : (item['price'] != null
                                                    ? Colors.green[700]
                                                    : Colors.grey[400]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // 3. Botão de Presente Público (Se não comprado)
                            if (!isPurchased)
                              IconButton(
                                icon: Icon(
                                  item['is_gift'] == true
                                      ? Icons.card_giftcard
                                      : Icons.card_giftcard_outlined,
                                  color: item['is_gift'] == true
                                      ? widget.themeColor
                                      : Colors.grey[400],
                                ),
                                onPressed: () => _toggleGiftStatus(
                                  item['id'],
                                  item['is_gift'] == true,
                                ),
                                tooltip: item['is_gift'] == true
                                    ? "Na lista de presentes"
                                    : "Disponibilizar como presente",
                              ),

                            const SizedBox(width: 8),

                            // 4. Checkbox Customizado
                            GestureDetector(
                              onTap: () => _toggleItem(item['id'], isPurchased),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isPurchased
                                      ? widget.themeColor.withOpacity(0.2)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isPurchased
                                        ? widget.themeColor
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: isPurchased
                                    ? Icon(
                                        Icons.check,
                                        size: 16,
                                        color: widget.themeColor,
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
