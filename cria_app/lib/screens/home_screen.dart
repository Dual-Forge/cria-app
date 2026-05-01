import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:url_launcher/url_launcher.dart';
import '../utils/baby_data.dart';
import '../services/pregnancy_ai_service.dart';
import '../services/gemini_service.dart';
import 'chatbot_screen.dart';
import '../widgets/baby_card/baby_card_widget.dart';

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

class _HomePregnancyScreenState extends State<HomePregnancyScreen>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  late ScrollController _scrollController;

  // AI Service logic
  final PregnancyAIService _fallbackAiService = PregnancyAIService();
  final GeminiService _geminiService = GeminiService();
  List<PregnancyTip> _aiTips = [];
  bool _isLoadingTips = false; // Start false to trigger load in build
  String? _weeklyFocus;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _heartScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heartController.dispose();
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

    if (_geminiService.isConfigured) {
      // Coleta dados extras da usuária, se existirem (Padrão para MVP: null)
      final userData = {
        'baby_name': widget.babyName ?? '',
        'baby_gender': widget.babyGender ?? '',
        'role': userRole,
      };

      final insights = await _geminiService.getPregnancyInsights(
        weeks,
        userData,
      );
      if (insights != null) {
        tips = [
          PregnancyTip(
            category: "Corpo",
            content: insights['body'] ?? '',
            iconEmoji: "🧘‍♀️",
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
              iconEmoji: "🏃‍♀️",
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
      body: _buildOverviewTab(),
    );
  }

  Widget _buildDynamicTitle(DateTime? actualDumDate) {
    String nameToDisplay = widget.babyName ?? "seu bebê";
    String textPrefix = "Aguardando a chegada de ";
    String textSuffix = ".";
    bool isBorn = false;

    if (actualDumDate != null) {
      final edd = actualDumDate.add(const Duration(days: 280));
      final daysRemaining = edd.difference(DateTime.now()).inDays;

      if (daysRemaining > 0) {
        textPrefix =
            "Faltam aproximadamente $daysRemaining dias para a chegada de ";
        textSuffix = ".";
      } else if (daysRemaining == 0) {
        textPrefix = "É hoje! O grande dia da chegada de ";
        textSuffix = ".";
      } else {
        isBorn = true;
        textPrefix = "";
        textSuffix = " nasceu há ${daysRemaining.abs()} dias!";
      }
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _heartScale,
        builder: (context, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.petitFormalScript(
                  fontSize: 26,
                  color: const Color(0xFF2D3142),
                ),
                children: [
                  if (isBorn) ...[
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Transform.scale(
                        scale: _heartScale.value,
                        child: Text(
                          nameToDisplay,
                          style: GoogleFonts.petitFormalScript(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: widget.themeColor,
                            shadows: [
                              Shadow(
                                color: widget.themeColor.withValues(alpha: 0.5),
                                blurRadius: 10 * _heartScale.value,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    TextSpan(text: textSuffix),
                  ] else ...[
                    TextSpan(text: textPrefix),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Transform.scale(
                        scale: _heartScale.value,
                        child: Text(
                          nameToDisplay,
                          style: GoogleFonts.petitFormalScript(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: widget.themeColor,
                            shadows: [
                              Shadow(
                                color: widget.themeColor.withValues(alpha: 0.5),
                                blurRadius: 10 * _heartScale.value,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    TextSpan(text: textSuffix),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- ABA 1: VISÃO GERAL ---
  Widget _buildOverviewTab() {
    String centerName =
        widget.babyName?.toUpperCase() ??
        (widget.babyGender == 'menino'
            ? "MENINO"
            : (widget.babyGender == 'menina' ? "MENINA" : "BEBÊ"));

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.familyId != null
          ? Supabase.instance.client
                .from('profiles')
                .stream(primaryKey: ['id'])
                .eq('family_id', widget.familyId!)
          : const Stream.empty(),
      builder: (context, snapshot) {
        Map<String, dynamic>? momProfile;
        Map<String, dynamic>? dadProfile;
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
            if (momProfile['dum_date'] != null) {
              actualDumDate = DateTime.parse(momProfile['dum_date']);
              currentWeeks = _calculateWeeks(actualDumDate);
            }
          } catch (_) {}
          try {
            dadProfile = profiles.firstWhere((p) => p['role'] == 'pai');
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
        final double screenWidth = MediaQuery.of(context).size.width;
        final double heartContainerSize = screenWidth * 0.85;

        return CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- FASE 2: HERO SECTION (100vh) ---
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () {
                  _scrollController.animateTo(
                    MediaQuery.of(context).size.height,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                  );
                },
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      Transform.translate(
                        offset: const Offset(
                          0,
                          45,
                        ), // Puxa o texto para perto do coração (Auréola)
                        child: _buildDynamicTitle(actualDumDate),
                      ),

                      // Contêiner principal com o Coração e os Avatares
                      SizedBox(
                        width: heartContainerSize,
                        height: heartContainerSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. Fundo do Coração Pulsante
                            AnimatedBuilder(
                              animation: _heartScale,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _heartScale.value,
                                  child: CustomPaint(
                                    size: Size(
                                      heartContainerSize,
                                      heartContainerSize,
                                    ),
                                    painter: HeartBackgroundPainter(
                                      color: widget.themeColor.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // 2. Linha Tracejada Estática formando um Coração menor
                            CustomPaint(
                              size: Size(
                                heartContainerSize,
                                heartContainerSize,
                              ),
                              painter: HeartDashedPathPainter(
                                color: widget.themeColor.withValues(alpha: 0.6),
                              ),
                            ),

                            // 3. Avatares perfeitamente alinhados na linha
                            // Mamãe (Topo Esquerdo)
                            Positioned(
                              left: heartContainerSize * 0.10,
                              top: heartContainerSize * 0.15,
                              child: _buildAvatarFloat(
                                momProfile,
                                Colors.pinkAccent.shade100,
                                80,
                                momProfile?['nickname'] ?? "Mamãe",
                              ),
                            ),

                            // Papai (Topo Direito)
                            Positioned(
                              right: heartContainerSize * 0.10,
                              top: heartContainerSize * 0.15,
                              child: _buildAvatarFloat(
                                dadProfile,
                                Colors.blueGrey,
                                80,
                                dadProfile?['nickname'] ?? "Papai",
                              ),
                            ),

                            // Bebê (Base Centro)
                            Positioned(
                              bottom: heartContainerSize * 0.0,
                              child: _buildBabyAvatar(centerName),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Indicador de Scroll interativo
                      AnimatedBuilder(
                        animation: _heartController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, 10 * _heartController.value),
                            child: Column(
                              children: [
                                Text(
                                  "Deslize ou toque para continuar",
                                  style: TextStyle(
                                    color: widget.themeColor.withValues(
                                      alpha: 0.6,
                                    ),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  Icons.keyboard_double_arrow_down,
                                  color: widget.themeColor.withValues(
                                    alpha: 0.6,
                                  ),
                                  size: 30,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

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
                      if (babyProfile['expected_due_date'] != null) {
                        expectedDueDate = DateTime.parse(
                          babyProfile['expected_due_date'],
                        );
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

  Widget _buildBabyAvatar(String centerName) {
    // Tamanho padronizado: 80x80
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.themeColor.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: widget.themeColor.withValues(alpha: 0.05),
            child:
                widget.babyPhotoUrl != null && widget.babyPhotoUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      widget.babyPhotoUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.child_care_rounded,
                        color: widget.themeColor,
                        size: 40,
                      ),
                    ),
                  )
                : Icon(
                    Icons.child_care_rounded,
                    color: widget.themeColor,
                    size: 40,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          centerName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D3142),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFloat(
    Map<String, dynamic>? profile,
    Color color,
    double size,
    String label,
  ) {
    final String? photoUrl = profile?['photo_url'];
    // Size agora é sempre garantido em 80 de fora, mas o parâmetro 'size' dita o círculo
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: (photoUrl != null && photoUrl.isNotEmpty)
                ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Text(
                        profile?['nickname']?[0]?.toUpperCase() ??
                            label[0].toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Text(
                    profile?['nickname']?[0]?.toUpperCase() ??
                        label[0].toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D3142),
          ),
        ),
      ],
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

class HeartBackgroundPainter extends CustomPainter {
  final Color color;

  HeartBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = _createHeartPath(size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeartDashedPathPainter extends CustomPainter {
  final Color color;

  HeartDashedPathPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = _createHeartPath(size);
    final dashedPath = _createDashedPath(path, dashLength: 8, dashSpace: 6);

    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(
    Path source, {
    required double dashLength,
    required double dashSpace,
  }) {
    final Path dest = Path();
    for (final ui.PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = dashLength;
        dest.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length + dashSpace;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Path _createHeartPath(Size size) {
  final double width = size.width;
  final double height = size.height;
  final path = Path();
  // Começa no cleft (centro-topo)
  path.moveTo(0.5 * width, height * 0.35);
  // Curva da orelha esquerda
  path.cubicTo(
    0.2 * width,
    height * 0.05,
    -0.25 * width,
    height * 0.45,
    0.5 * width,
    height * 0.90,
  );
  // Volta para o cleft para curvar a direita
  path.moveTo(0.5 * width, height * 0.35);
  path.cubicTo(
    0.8 * width,
    height * 0.05,
    1.25 * width,
    height * 0.45,
    0.5 * width,
    height * 0.90,
  );
  return path;
}
