import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cria_app/features/ai_specialist/services/pregnancy_ai_service.dart';
import 'package:cria_app/features/ai_specialist/services/ai_service.dart';
import 'package:cria_app/features/ai_specialist/ui/chatbot_screen.dart';
import 'package:cria_app/widgets/baby_card/baby_card_widget.dart';

class HomePregnancyScreen extends StatefulWidget {
  final Color themeColor;
  final String? babyName;
  final String? babyGender;
  final String? babyPhotoUrl;
  final DateTime? dumDate;
  final String? familyCode;
  final String? familyId;

  const HomePregnancyScreen({
    super.key,
    required this.themeColor,
    this.babyName,
    this.babyGender,
    this.babyPhotoUrl,
    this.dumDate,
    this.familyCode,
    this.familyId,
  });

  @override
  State<HomePregnancyScreen> createState() => _HomePregnancyScreenState();
}

class _HomePregnancyScreenState extends State<HomePregnancyScreen> {
  // AI Service logic
  final PregnancyAIService _fallbackAiService = PregnancyAIService();
  final AIService _aiService = AIService();
  List<PregnancyTip> _aiTips = [];
  bool _isLoadingTips = false; // Start false to trigger load in build
  String? _weeklyFocus;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  int _calculateWeeks(DateTime? dum) {
    if (dum == null) return 0;
    final now = DateTime.now();
    final diff = now.difference(dum);
    int w = (diff.inDays / 7).floor();
    return w > 42 ? 42 : (w < 0 ? 0 : w);
  }

  Future<void> _loadAITips(int weeks, [String userRole = 'mae']) async {
    if (_aiTips.isNotEmpty) return;

    List<PregnancyTip> tips = [];
    final focus = await _fallbackAiService.getWeeklyFocus(weeks);

    if (_aiService.isConfigured) {
      final userData = {
        'baby_name': widget.babyName ?? '',
        'baby_gender': widget.babyGender ?? '',
        'role': userRole,
      };

      final insights = await _aiService.getPregnancyInsights(
        weeks,
        userData,
      );
      if (insights != null) {
        tips = [
          PregnancyTip(
            category: "Corpo",
            content: insights['body'] ?? '',
            iconEmoji: "🧘\u200d♀️",
          ),
          PregnancyTip(
            category: "Nutrição",
            content: insights['nutrition'] ?? '',
            iconEmoji: "🥦",
          ),
          PregnancyTip(
            category: "Bebê",
            content: insights['baby'] ?? '',
            iconEmoji: "👶",
          ),
          if (insights['mind']?.isNotEmpty == true)
            PregnancyTip(
              category: "Mente",
              content: insights['mind'] ?? '',
              iconEmoji: "🧠",
            ),
          if (insights['movement']?.isNotEmpty == true)
            PregnancyTip(
              category: "Movimento",
              content: insights['movement'] ?? '',
              iconEmoji: "🏃\u200d♀️",
            ),
          if (insights['connection']?.isNotEmpty == true)
            PregnancyTip(
              category: "Conexão",
              content: insights['connection'] ?? '',
              iconEmoji: "🤍",
            ),
        ];
      }
    }

    // Fallback if not configured or failed
    if (tips.isEmpty) {
      tips = await _fallbackAiService.fetchTipsForWeek(weeks);
    }

    if (mounted) {
      setState(() {
        _aiTips = tips;
        _weeklyFocus = focus;
        _isLoadingTips = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(child: _buildOverviewTab()),
    );
  }

  // --- ABA 1: VISÃO GERAL ---
  Widget _buildOverviewTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.familyId != null
          ? Supabase.instance.client
                .from('profiles')
                .stream(primaryKey: ['id'])
                .eq('family_id', widget.familyId!)
          : const Stream.empty(),
      builder: (context, snapshot) {
        Map<String, dynamic>? momProfile;
        DateTime? actualDumDate = widget.dumDate;
        int currentWeeks = _calculateWeeks(actualDumDate);
        String role = 'mae';

        if (snapshot.hasData) {
          final profiles = snapshot.data!;
          try {
            final myProfile = profiles.firstWhere(
              (p) => p['id'] == Supabase.instance.client.auth.currentUser?.id,
            );
            role = myProfile['role'] ?? 'mae';
          } catch (_) {}

          try {
            momProfile = profiles.firstWhere((p) => p['role'] == 'mae');
            final rawDum = momProfile['dum_date'];
            if (rawDum != null && rawDum.toString().trim().isNotEmpty) {
              try {
                actualDumDate = DateTime.parse(rawDum.toString().trim());
                currentWeeks = _calculateWeeks(actualDumDate);
              } catch (e) {
                debugPrint('Erro ao parsear dum_date na Home: $e');
              }
            }
          } catch (_) {}
        }

        if (snapshot.connectionState != ConnectionState.waiting ||
            snapshot.hasData) {
          if (_aiTips.isEmpty && !_isLoadingTips) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isLoadingTips = true);
              _loadAITips(currentWeeks, role);
            });
          }
        }

        // final babyData = BabyData.getData(currentWeeks); // Unused

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- FASE 3: BABY CARD (NOVO) ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: widget.familyId != null
                      ? Supabase.instance.client
                            .from('baby_profile')
                            .stream(primaryKey: ['id'])
                            .eq('family_id', widget.familyId!)
                      : const Stream.empty(),
                  builder: (context, babySnapshot) {
                    String? profilePhotoUrl = widget.babyPhotoUrl;
                    int? lastBpm;
                    int kickCount = 0;
                    DateTime? expectedDueDate;

                    if (babySnapshot.hasData && babySnapshot.data!.isNotEmpty) {
                      final babyProfile = babySnapshot.data!.first;
                      if (babyProfile['profile_photo_url'] != null &&
                          babyProfile['profile_photo_url'].isNotEmpty) {
                        profilePhotoUrl = babyProfile['profile_photo_url'];
                      }
                      lastBpm = babyProfile['last_bpm'];
                      kickCount = babyProfile['kick_count'] ?? 0;
                      final rawExpected = babyProfile['expected_due_date'];
                      if (rawExpected != null && rawExpected.toString().trim().isNotEmpty) {
                        try {
                          expectedDueDate = DateTime.parse(rawExpected.toString().trim());
                        } catch (e) {
                          debugPrint('Erro ao parsear expected_due_date na Home: $e');
                        }
                      }
                    }

                    return BabyCardWidget(
                      profilePhotoUrl: profilePhotoUrl,
                      lastBpm: lastBpm,
                      expectedDueDate: expectedDueDate,
                      dumDate: actualDumDate,
                      kickCount: kickCount,
                      babyName: widget.babyName ?? 'Bebê',
                      familyId: widget.familyId ?? '',
                      themeColor: widget.themeColor,
                      onKickCountUpdated: (newCount) {
                        // Atualizar UI se necessário
                      },
                      onError: (error) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Erro: $error')));
                      },
                    );
                  },
                ),
              ),
            ),

            // --- ESPECIALISTA NANDA (MÓVEL) ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatbotScreen(babyName: widget.babyName),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.pinkAccent.shade100.withOpacity(0.2),
                          Colors.pinkAccent.shade100.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.pinkAccent.shade100.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          backgroundImage: const AssetImage(
                            'assets/images/nanda.png',
                          ),
                          onBackgroundImageError: (_, __) {},
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Dúvidas? Pergunte à especialista Nanda",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2D3142),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Sua especialista virtual 24h",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- FASE 4: INSIGHTS IA ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cantinho do Cuidado",
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2D3142),
                                  ),
                            ),
                            if (_weeklyFocus != null)
                              Text(
                                _weeklyFocus!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_isLoadingTips && _aiTips.isEmpty)
                      _buildShimmerTips()
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 0.9,
                            ),
                        itemCount: _aiTips.length,
                        itemBuilder: (context, index) {
                          return _buildPremiumTipCard(_aiTips[index], index);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiumTipCard(PregnancyTip tip, int index) {
    final colors = [
      const Color(0xFFE3F2FD),
      const Color(0xFFE0F2F1), // Substituindo o roxo proibido por Teal
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF3E0),
    ];
    final accentColors = [
      Colors.blue.shade700,
      Colors.teal.shade700, // Substituindo o roxo proibido por Teal
      Colors.green.shade700,
      Colors.orange.shade700,
    ];

    final bg = colors[index % colors.length];
    final accent = accentColors[index % accentColors.length];

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(tip.iconEmoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Text(
                      tip.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  tip.content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3142),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tip.iconEmoji, style: const TextStyle(fontSize: 28)),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 18,
                  color: accent.withOpacity(0.5),
                ),
              ],
            ),
            const Spacer(),
            Text(
              tip.category.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: accent.withOpacity(0.8),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              tip.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerTips() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.9,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(25),
          ),
        );
      },
    );
  }
}
