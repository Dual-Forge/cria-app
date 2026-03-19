import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class GiftsManagementScreen extends StatefulWidget {
  final Color currentTheme;
  final String? familyId;

  const GiftsManagementScreen({
    super.key,
    required this.currentTheme,
    this.familyId,
  });

  @override
  State<GiftsManagementScreen> createState() => _GiftsManagementScreenState();
}

class _GiftsManagementScreenState extends State<GiftsManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _gifts = [];
  String? _currentUserName;
  String? _babyName;

  @override
  void initState() {
    super.initState();
    _loadGiftsAndProfile();
  }

  Future<void> _loadGiftsAndProfile() async {
    if (widget.familyId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user != null) {
        final profileData = await client
            .from('profiles')
            .select('role, nickname')
            .eq('id', user.id)
            .maybeSingle();

        if (profileData != null) {
          _currentUserName = profileData['nickname'];
        }
      }

      final familyData = await client
          .from('families')
          .select('baby_name')
          .eq('id', widget.familyId!)
          .maybeSingle();

      if (familyData != null) {
        _babyName = familyData['baby_name'];
      }

      final response = await client
          .from('gift_contributions')
          .select('''
            *,
            items (name, category)
          ''')
          .eq('family_id', widget.familyId!)
          .order('created_at', ascending: false);

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

  Future<void> _sendThankYou(Map<String, dynamic> gift) async {
    // 1. Define o nome ou apelido (Requisito 7.2)
    final giverNameOrNickname = gift['giver_nickname']?.toString().isNotEmpty == true 
        ? gift['giver_nickname'] 
        : (gift['giver_name'] ?? 'Padrinho/Madrinha');

    // 2. Limpa o telefone e garante o prefixo 55 apenas se necessário
    String rawPhone = gift['giver_phone']?.toString().replaceAll(RegExp(r'[^\d]'), '') ?? '';
    if (rawPhone.isNotEmpty && !rawPhone.startsWith('55')) {
      rawPhone = '55$rawPhone';
    }

    if (rawPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telefone não disponível para este doador.')),
        );
      }
      return;
    }

    // 3. Formata a mensagem padrão (Requisito 8.3 e 8.4)
    final text = 'Oi $giverNameOrNickname, muito obrigado pelo presente! 💛';
    final encodedText = Uri.encodeComponent(text);
    final url = Uri.parse('https://wa.me/$rawPhone?text=$encodedText');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);

      // Lógica de atualização do banco (Mantida conforme o original)
      try {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        final currentThankedBy = List<String>.from(gift['thanked_by'] ?? []);

        if (currentUserId != null && !currentThankedBy.contains(currentUserId)) {
          currentThankedBy.add(currentUserId);
          await Supabase.instance.client
              .from('gift_contributions')
              .update({'thanked': true, 'thanked_by': currentThankedBy})
              .eq('id', gift['id']);

          setState(() {
            final index = _gifts.indexWhere((g) => g['id'] == gift['id']);
            if (index != -1) {
              _gifts[index]['thanked'] = true;
              _gifts[index]['thanked_by'] = currentThankedBy;
            }
          });
        }
      } catch (e) {
        debugPrint('Erro ao marcar como agradecido: $e');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mural de Presentes'),
        backgroundColor: widget.currentTheme,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.familyId != null)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Compartilhar Link Público',
              onPressed: () {
                final link =
                    'https://web-jade-ten-51.vercel.app/presentes/${widget.familyId}';
                Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Link do Mural copiado para a área de transferência! 🔗',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.currentTheme))
          : _gifts.isEmpty
          ? _buildEmptyState()
          : _buildGiftsList(),
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
            'Nenhum presente recebido ainda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Compartilhe a sua lista com amigos e familiares para começar a receber mimos!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftsList() {
    int totallyThankedCount = _gifts.where((g) {
      final thankedBy = List<String>.from(g['thanked_by'] ?? []);
      return thankedBy.length >= 2;
    }).length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: widget.currentTheme.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Recebidos: ${_gifts.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Agradecidos: $totallyThankedCount/${_gifts.length}',
                style: TextStyle(
                  color: totallyThankedCount == _gifts.length
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _gifts.length,
            itemBuilder: (context, index) {
              final gift = _gifts[index];
              final currentUserId =
                  Supabase.instance.client.auth.currentUser?.id;
              final thankedBy = List<String>.from(gift['thanked_by'] ?? []);
              final hasUserThanked =
                  currentUserId != null && thankedBy.contains(currentUserId);
              final thankedCount = thankedBy.length;
              final isTotallyThanked = thankedCount >= 2;

              final itemObj = gift['items'] as Map<String, dynamic>?;
              final itemName = itemObj != null
                  ? itemObj['name']
                  : 'Presente Genérico';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: widget.currentTheme.withValues(
                              alpha: 0.2,
                            ),
                            child: Icon(
                              Icons.person,
                              color: widget.currentTheme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gift['giver_nickname'] ??
                                      gift['giver_name'] ??
                                      'Visitante',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Presenteou com: $itemName',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isTotallyThanked)
                            const Icon(Icons.check_circle, color: Colors.green),
                        ],
                      ),
                      if (gift['message_to_parents'] != null &&
                          gift['message_to_parents'].toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '"${gift['message_to_parents']}"',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progresso de Agradecimento',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '$thankedCount/2',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isTotallyThanked
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (thankedCount / 2).clamp(0.0, 1.0),
                            backgroundColor: Colors.grey[300],
                            color: isTotallyThanked
                                ? Colors.green
                                : Colors.orange,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          if (isTotallyThanked)
                            const Text(
                              'O papai e a mamãe já agradeceram! ✅',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else
                            Text(
                              hasUserThanked
                                  ? 'Aguardando o outro responsável agradecer. ⏳'
                                  : 'Falta você agradecer! 💌',
                              style: TextStyle(
                                color: hasUserThanked
                                    ? Colors.grey[600]
                                    : Colors.orange[800],
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _sendThankYou(gift),
                          icon: const Icon(Icons.chat),
                          label: Text(
                            hasUserThanked
                                ? 'Reenviar Agradecimento'
                                : 'Agradecer no WhatsApp',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasUserThanked
                                ? Colors.grey[300]
                                : Colors.green,
                            foregroundColor: hasUserThanked
                                ? Colors.grey[700]
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
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
  }
}
