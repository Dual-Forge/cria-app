import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gemini;
import 'package:cria_app/features/ai_specialist/services/gemini_service.dart';
import 'package:cria_app/features/ai_specialist/repositories/chat_repository.dart';

class ChatbotScreen extends StatefulWidget {
  final String? babyName;

  const ChatbotScreen({super.key, this.babyName});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  late final ChatRepository _chatRepository = ChatRepository(Supabase.instance.client);

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  late gemini.ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      int currentWeeks = 0;
      String userRole = 'mae';
      String userName = '';
      String babyName = widget.babyName ?? 'Bebê';

      try {
        final profilesData = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id);

        if (profilesData.isNotEmpty) {
          final myProfile = profilesData[0];
          userRole = myProfile['role'] ?? 'mae';
          userName = myProfile['nickname'] ?? '';

          if (myProfile['family_id'] != null) {
            final familyId = myProfile['family_id'];

            // Query Families table to get the definite baby_name
            final familyRow = await Supabase.instance.client
                .from('families')
                .select()
                .eq('id', familyId)
                .maybeSingle();

            if (familyRow != null && familyRow['baby_name'] != null) {
              babyName = familyRow['baby_name'];
            }

            final familyData = await Supabase.instance.client
                .from('profiles')
                .select()
                .eq('family_id', familyId);

            final momProfile = familyData.firstWhere(
              (p) => p['role'] == 'mae',
              orElse: () => <String, dynamic>{},
            );
            if (momProfile['dum_date'] != null) {
              final dum = DateTime.parse(momProfile['dum_date'].toString());
              final diff = DateTime.now().difference(dum);
              currentWeeks = (diff.inDays / 7).floor();
            }
          }
        }
      } catch (e) {
        debugPrint('Erro contexto: \$e');
      }

      // 2. Busca mensagens do usuário OU da família
      final query = Supabase.instance.client
          .from('chat_messages')
          .select()
          .order('created_at', ascending: true);

      final data = await query;
      // Simulando o or() que falharia se family_id não existir na tabela antiga
      // Como migramos a tabela agora, vamos aceitar o select() normal por enquanto
      // e filtrar na memória caso RLS permita ver a da família também

      final mappedMsgs = List<Map<String, dynamic>>.from(data);

      if (mappedMsgs.isEmpty) {
        mappedMsgs.add({
          'role': 'model',
          'content': 'Olá! Sou a Nanda, a especialista virtual de vocês. Como posso ajudar a tranquilizar o dia de hoje? ✨🤍',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 3. Monta o histórico pro Gemini
      List<gemini.Content> history = [];
      for (var msg in mappedMsgs) {
        if (msg['role'] == 'user') {
          history.add(gemini.Content.text(msg['content']));
        } else if (msg['role'] == 'model') {
          history.add(gemini.Content.model([gemini.TextPart(msg['content'])]));
        }
      }

      // 4. Inicia a sessão
      if (_geminiService.isConfigured) {
        _chatSession = _geminiService.startChat(
          history,
          userData: {
            'role': userRole,
            'weeks': currentWeeks,
            'userName': userName,
            'babyName': babyName,
          },
        );
      }

      setState(() {
        _messages = mappedMsgs;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Erro ao carregar chat: \$e');
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || !_geminiService.isConfigured || _isTyping) return;

    _messageController.clear();

    // Mostra a msg do usuário na tela instantaneamente
    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
      });
      _isTyping = true;
    });
    _scrollToBottom();

    // Salva a msg do user no BD via ChatRepository
    await _chatRepository.saveMessage(content: text, role: 'user');

    try {
      // Chama o Gemini
      final response = await _chatSession.sendMessage(
        gemini.Content.text(text),
      );
      final replyText = response.text ?? 'Desculpe, não consegui entender.';

      // Mostra a resposta na tela
      setState(() {
        _messages.add({
          'role': 'model',
          'content': replyText,
          'created_at': DateTime.now().toIso8601String(),
        });
        _isTyping = false;
      });
      _scrollToBottom();

      // Salva a resposta no BD via ChatRepository
      await _chatRepository.saveMessage(content: replyText, role: 'model');

    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'role': 'model',
          'content': 'Houve um erro de conexão. Tente novamente mais tarde.',
          'created_at': DateTime.now().toIso8601String(),
        });
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_geminiService.isConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cria AI')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'A Inteligência Artificial ainda não foi configurada.\\nPor favor, defina a GEMINI_API_KEY no ambiente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.pinkAccent.withOpacity(0.1),
              backgroundImage: const AssetImage('assets/images/nanda.png'),
              onBackgroundImageError: (_, __) {},
              child: const Icon(Icons.support_agent, size: 16, color: Colors.pinkAccent),
            ),
            const SizedBox(width: 10),
            const Text(
              'Nanda',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.pinkAccent.shade700,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Disclaimer Topo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.amber[50],
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.amber[800],
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '(ℹ️ A Nanda é uma IA de apoio e bem-estar. Sempre consulte seu obstetra para decisões médicas.)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return _buildMessageBubble(msg['content'], isUser);
                    },
                  ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nanda está digitando...',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            ),
          // Caixa de texto
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Pergunte sobre sua gestação...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.pinkAccent.shade700,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.pinkAccent.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : null,
            bottomLeft: !isUser ? const Radius.circular(0) : null,
          ),
          boxShadow: isUser
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          // Tratar markdown simples removendo asteriscos por enquanto para design limpo
          text.replaceAll('**', ''),
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF2D3142),
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
