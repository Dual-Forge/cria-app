import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:url_launcher/url_launcher.dart';
import '../utils/baby_data.dart';
import '../services/pregnancy_ai_service.dart';
import '../services/gemini_service.dart';
import 'chatbot_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'shopping_list_screen.dart';
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
  late TabController _tabController;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  String _calendarView = 'Dia';

  // AI Service logic
  final PregnancyAIService _fallbackAiService = PregnancyAIService();
  final GeminiService _geminiService = GeminiService();
  List<PregnancyTip> _aiTips = [];
  bool _isLoadingTips = false; // Start false to trigger load in build
  String? _weeklyFocus;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _tabController = TabController(length: 2, vsync: this);

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _heartScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  /// Converts gestational week (1-42) to pregnancy month (1-9).
  int _weekToMonth(int week) {
    if (week <= 4) return 1;
    if (week <= 8) return 2;
    if (week <= 13) return 3;
    if (week <= 17) return 4;
    if (week <= 22) return 5;
    if (week <= 27) return 6;
    if (week <= 31) return 7;
    if (week <= 35) return 8;
    return 9;
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

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  Future<void> _openMap(String address) async {
    final googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}";
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(
        Uri.parse(googleMapsUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
        ),
        actions: const [SizedBox(width: 10)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor:
                  Colors.transparent, // Fix the hidden line below Tabs
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: widget.themeColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: widget.themeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              tabs: const [
                Tab(text: "Visão Geral"),
                Tab(text: "Agenda"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [_buildOverviewTab(), _buildAppointmentsTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatbotScreen(babyName: widget.babyName),
            ),
          );
        },
        backgroundColor: const ui.Color.fromARGB(255, 255, 128, 198),
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text(
          'Doula',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
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

        final babyData = BabyData.getData(currentWeeks);
        final double screenWidth = MediaQuery.of(context).size.width;
        final double heartContainerSize = screenWidth * 0.85;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- FASE 2: HERO SECTION (100vh) ---
            SliverToBoxAdapter(
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
                            size: Size(heartContainerSize, heartContainerSize),
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

                    // Indicador de Scroll
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.themeColor.withValues(alpha: 0.5),
                      size: 40,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- AÇÕES RÁPIDAS ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChatbotScreen(babyName: widget.babyName),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          "Chat com IA",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const ui.Color.fromARGB(
                            255,
                            255,
                            128,
                            198,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: const ui.Color.fromARGB(
                            255,
                            255,
                            128,
                            198,
                          ).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShoppingListScreen(
                                currentTheme: widget.themeColor,
                                familyId: widget.familyId,
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.child_care,
                          color: widget.themeColor,
                          size: 20,
                        ),
                        label: Text(
                          "Enxoval",
                          style: TextStyle(
                            color: widget.themeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: Colors.black.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                    String? profilePhotoUrl;
                    int? lastBpm;
                    int kickCount = 0;
                    DateTime? expectedDueDate;

                    if (babySnapshot.hasData && babySnapshot.data!.isNotEmpty) {
                      final babyProfile = babySnapshot.data!.first;
                      profilePhotoUrl = babyProfile['profile_photo_url'];
                      lastBpm = babyProfile['last_bpm'];
                      kickCount = babyProfile['kick_count'] ?? 0;
                      if (babyProfile['expected_due_date'] != null) {
                        expectedDueDate = DateTime.parse(babyProfile['expected_due_date']);
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: $error')),
                        );
                      },
                    );
                  },
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
                            const Text(
                              "Insights IA",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D3142),
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
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _aiTips.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 15),
                          itemBuilder: (context, index) {
                            return _buildPremiumTipCard(_aiTips[index], index);
                          },
                        ),
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
        width: 160,
        padding: const EdgeInsets.all(20),
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
    return Row(
      children: List.generate(
        2,
        (index) => Container(
          width: 160,
          height: 180,
          margin: const EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  // --- ABA 2: AGENDA MÉDICA ---
  Widget _buildAppointmentsTab() {
    if (widget.familyId == null) {
      return const Center(child: Text("Carregando família..."));
    }

    return StreamBuilder(
      stream: Supabase.instance.client
          .from('appointments')
          .stream(primaryKey: ['id'])
          .eq('family_id', widget.familyId!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<dynamic> rawList = snapshot.data!;
          _events = {};
          for (var item in rawList) {
            final date = DateTime.parse(item['appointment_date']);
            final normalizedDate = DateTime(date.year, date.month, date.day);
            if (_events[normalizedDate] == null) _events[normalizedDate] = [];
            _events[normalizedDate]!.add(item);
          }
        }

        List<dynamic> displayEvents = [];
        if (_calendarView == 'Próximas') {
          final now = DateTime.now().subtract(const Duration(hours: 2));
          for (var list in _events.values) {
            for (var item in list) {
              if (DateTime.parse(item['appointment_date']).isAfter(now)) {
                displayEvents.add(item);
              }
            }
          }
          displayEvents.sort(
            (a, b) => a['appointment_date'].compareTo(b['appointment_date']),
          );
        } else if (_calendarView == 'Dia') {
          displayEvents = _getEventsForDay(_selectedDay ?? DateTime.now());
          displayEvents.sort(
            (a, b) => a['appointment_date'].compareTo(b['appointment_date']),
          );
        } else {
          for (var list in _events.values) {
            displayEvents.addAll(list);
          }
          displayEvents.sort(
            (a, b) => b['appointment_date'].compareTo(a['appointment_date']),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 80),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(15),
              child: TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getEventsForDay,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: widget.themeColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: widget.themeColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: widget.themeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.themeColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                onDaySelected: (s, f) => setState(() {
                  _selectedDay = s;
                  _focusedDay = f;
                  _calendarView = 'Dia';
                }),
                onPageChanged: (f) => _focusedDay = f,
              ),
            ),

            const SizedBox(height: 20),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    "Dia Selecionado",
                    _calendarView == 'Dia',
                    () => setState(() => _calendarView = 'Dia'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    "Próximas",
                    _calendarView == 'Próximas',
                    () => setState(() => _calendarView = 'Próximas'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    "Todas",
                    _calendarView == 'Todos',
                    () => setState(() => _calendarView = 'Todos'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (displayEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 40,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Nenhum agendamento.",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...displayEvents.map((e) => _buildAppointmentCard(e)),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showAddAppointmentSheet(widget.familyId!),
              icon: const Icon(Icons.add),
              label: const Text("Nova Consulta"),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: widget.themeColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                minimumSize: const Size(double.infinity, 54),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? widget.themeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: widget.themeColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> apt) {
    final date = DateTime.parse(apt['appointment_date']);
    final hasPhoto = apt['photo_url'] != null;
    final address = apt['address'];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showAppointmentDetails(apt),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: widget.themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: hasPhoto
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            apt['photo_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.broken_image,
                              color: widget.themeColor,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.description_outlined,
                          color: widget.themeColor,
                        ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apt['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM HH:mm').format(date),
                        style: TextStyle(
                          color: widget.themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Dr(a) ${apt['doctor_name'] ?? '-'}",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (address != null && address.toString().isNotEmpty)
                  IconButton(
                    onPressed: () => _openMap(address),
                    icon: Icon(Icons.location_on, color: Colors.blue.shade300),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> apt) {
    final date = DateTime.parse(apt['appointment_date']);
    final address = apt['address'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.calendar_month, color: widget.themeColor),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy • HH:mm').format(date),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      apt['title'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 25),

            _detailRow(
              Icons.person,
              "Paciente",
              apt['patient_name'] ?? 'Não informado',
            ),
            _detailRow(
              Icons.medical_services,
              "Médico",
              apt['doctor_name'] ?? 'Não informado',
            ),

            if (address != null && address.toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: InkWell(
                  onTap: () => _openMap(address),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_pin, color: Colors.blue.shade400),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAppointmentSheet(String familyId) {
    final titleController = TextEditingController();
    final doctorController = TextEditingController();
    final addressController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    bool isSaving = false;
    Uint8List? agendaImageBytes;
    // bool _isUploadingAgendaImage = false; // Removed unused

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> pickImage() async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 50,
            );
            if (picked != null) {
              final bytes = await picked.readAsBytes();
              setSheetState(() {
                agendaImageBytes = bytes;
              });
            }
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
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
                Text(
                  "Nova Consulta",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.themeColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      _buildModernField(
                        "Título (ex: Ultrassom)",
                        titleController,
                        true,
                        Icons.title,
                      ),
                      const SizedBox(height: 15),
                      _buildModernField(
                        "Médico / Especialidade",
                        doctorController,
                        true,
                        Icons.medical_services,
                      ),
                      const SizedBox(height: 15),
                      _buildModernField(
                        "Endereço / Clínica",
                        addressController,
                        true,
                        Icons.location_on,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                  locale: const Locale('pt', 'BR'),
                                );
                                if (d != null) {
                                  setSheetState(() => selectedDate = d);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: widget.themeColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(selectedDate),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (t != null) {
                                  setSheetState(() => selectedTime = t);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: widget.themeColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      selectedTime.format(context),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // FOTO UPLOAD UI
                      const Text(
                        "Foto / Documento (Opcional)",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: pickImage,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: (agendaImageBytes != null)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.memory(
                                        agendaImageBytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      Icons.camera_alt,
                                      color: Colors.grey[400],
                                    ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          if (agendaImageBytes != null)
                            TextButton(
                              onPressed: () => setSheetState(() {
                                agendaImageBytes = null;
                              }),
                              child: const Text(
                                "Remover",
                                style: TextStyle(color: Colors.red),
                              ),
                            )
                          else
                            const Text(
                              "Toque para adicionar",
                              style: TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (titleController.text.isEmpty) return;
                            setSheetState(() => isSaving = true);
                            try {
                              String? uploadedPhotoUrl;
                              // Upload logic
                              if (agendaImageBytes != null) {
                                final user =
                                    Supabase.instance.client.auth.currentUser;
                                final fileName =
                                    'agenda_photos/${user!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

                                await Supabase.instance.client.storage
                                    .from('agenda_photos')
                                    .uploadBinary(
                                      fileName,
                                      agendaImageBytes!,
                                      fileOptions: const FileOptions(
                                        contentType: 'image/jpeg',
                                      ),
                                    );
                                uploadedPhotoUrl = Supabase
                                    .instance
                                    .client
                                    .storage
                                    .from('agenda_photos')
                                    .getPublicUrl(fileName);
                              }

                              final dt = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );
                              await Supabase.instance.client
                                  .from('appointments')
                                  .insert({
                                    'family_id': familyId,
                                    'title': titleController.text,
                                    'doctor_name': doctorController.text,
                                    'address': addressController.text,
                                    'appointment_date': dt.toIso8601String(),
                                    'created_at': DateTime.now()
                                        .toIso8601String(),
                                    'photo_url': uploadedPhotoUrl,
                                  });
                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              setSheetState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Erro: $e")),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.themeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Agendar Consulta",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Reuse the modern field method, but we need to define it or duplicate it?
  // Since it's private in Settings, I'll define a local helper here.
  Widget _buildModernField(
    String label,
    TextEditingController controller,
    bool isEditing,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          icon: Icon(icon, color: widget.themeColor),
          border: InputBorder.none,
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),
      ),
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
