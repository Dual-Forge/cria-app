import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cria_app/app/app_dependencies.dart';
import 'package:cria_app/features/ai_specialist/services/ai_service.dart';
import 'package:cria_app/features/ai_specialist/repositories/chat_repository.dart';

class ChatbotScreen extends StatefulWidget {
  final String? babyName;

  /// Client Supabase injetado (DI). O AIService usa o proxy via functions.
  final SupabaseClient? supabaseClient;

  const ChatbotScreen({super.key, this.babyName, this.supabaseClient});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final SupabaseClient _client =
      widget.supabaseClient ?? AppDependencies.client;
  late final AIService _aiService = AIService(_client);
  late final ChatRepository _chatRepository = ChatRepository(_client);

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;

  // Dados dinâmicos do usuário para o system prompt da Nanda
  String _userName = '';
  String _userRole = 'mae';
  String _babyName = 'Bebê';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      _babyName = widget.babyName ?? 'Bebê';

      try {
        final profilesData = await _client
            .from('profiles')
            .select()
            .eq('id', user.id);

        if (profilesData.isNotEmpty) {
          final myProfile = profilesData[0];
          _userRole = myProfile['role'] ?? 'mae';
          _userName = myProfile['nickname'] ?? '';

          if (myProfile['family_id'] != null) {
            final familyId = myProfile['family_id'];

            final familyRow = await _client
                .from('families')
                .select()
                .eq('id', familyId)
                .maybeSingle();

            if (familyRow != null && familyRow['baby_name'] != null) {
              _babyName = familyRow['baby_name'];
            }
          }
        }
      } catch (e) {
        debugPrint('Erro contexto: $e');
      }

      // Busca mensagens do Supabase
      final data = await _client
          .from('chat_messages')
          .select()
          .order('created_at', ascending: true);

      final mappedMsgs = List<Map<String, dynamic>>.from(data);

      if (mappedMsgs.isEmpty) {
        mappedMsgs.add({
          'role': 'assistant',
          'content':
              'Olá! Sou a Nanda, a especialista virtual de vocês. Como posso ajudar a tranquilizar o dia de hoje? ✨🤍',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (!mounted) return;
      setState(() {
        _messages = mappedMsgs;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Erro ao carregar chat: $e');
      if (mounted) setState(() => _isLoading = false);
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
    if (text.isEmpty || _isTyping) return;

    _messageController.clear();

    // Mostra a mensagem do usuário instantaneamente
    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
      });
      _isTyping = true;
    });
    _scrollToBottom();

    // 1. Salva no Supabase (isolado — não bloqueia a IA)
    try {
      await _chatRepository.saveMessage(content: text, role: 'user');
    } catch (dbError) {
      debugPrint('[Supabase] Erro ao salvar mensagem do usuário: $dbError');
    }

    // 2. Monta o histórico no formato Groq: apenas role user/assistant
    final groqHistory = _messages
        .where((m) => m['role'] == 'user' || m['role'] == 'assistant')
        .map(
          (m) => {
            'role': m['role'] as String,
            'content': m['content'] as String,
          },
        )
        .toList();

    // 3. Chama o AIService
    try {
      final reply = await _aiService.sendChatMessage(
        history: groqHistory,
        userName: _userName,
        userRole: _userRole,
        babyName: _babyName,
      );

      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': reply,
          'created_at': DateTime.now().toIso8601String(),
        });
      });
      _scrollToBottom();

      // 4. Salva a resposta da IA (isolado)
      try {
        await _chatRepository.saveMessage(content: reply, role: 'model');
      } catch (dbError) {
        debugPrint('[Supabase] Erro ao salvar resposta da IA: $dbError');
      }
    } catch (aiError) {
      debugPrint('[AIService] Erro: $aiError');
      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Ops, tive um problema técnico. Pode tentar novamente? 🤍',
          'created_at': DateTime.now().toIso8601String(),
        });
      });
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.pinkAccent.withValues(alpha: 0.1),
              backgroundImage: const AssetImage('assets/images/nanda.png'),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 10),
            const Text('Nanda', style: TextStyle(fontWeight: FontWeight.bold)),
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
                Icon(Icons.info_outline, color: Colors.amber[800], size: 20),
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
                      return _buildMessageBubble(msg['content'] as String, isUser);
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
                  color: Colors.black.withValues(alpha: 0.05),
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
                    onSubmitted: _isTyping ? null : (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor:
                      _isTyping ? Colors.grey[300] : Colors.pinkAccent.shade700,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isTyping ? null : _sendMessage,
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
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
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
