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

class HomePregnancyScreen extends StatefulWidget {
  final Color themeColor;
  final String? babyName;
  final String? babyGender;
  final DateTime? dumDate;
  final String? familyCode;
  final String? familyId;

  const HomePregnancyScreen({
    super.key,
    required this.themeColor,
    this.babyName,
    this.babyGender,
    this.dumDate,
    this.familyCode,
    this.familyId,
  });

  @override
  State<HomePregnancyScreen> createState() => _HomePregnancyScreenState();
}

class _HomePregnancyScreenState extends State<HomePregnancyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      backgroundColor: const Color(0xFFF8F9FE),
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
        backgroundColor: Colors.teal[600],
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text(
          'Cria AI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
        int currentWeeks = _calculateWeeks(widget.dumDate); // fallback default
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
              currentWeeks = _calculateWeeks(
                DateTime.parse(momProfile['dum_date']),
              );
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

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 150, 20, 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(
                  height: 140,
                  width: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 20,
                        top: 10,
                        child: _buildAvatarFloat(
                          dadProfile,
                          Colors.blueGrey,
                          50,
                          "Pai",
                        ),
                      ),
                      Positioned(
                        right: 20,
                        top: 10,
                        child: _buildAvatarFloat(
                          momProfile,
                          Colors.pinkAccent.shade100,
                          50,
                          "Mãe",
                        ),
                      ),
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.themeColor.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: widget.themeColor.withOpacity(
                              0.05,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize
                                  .min, // Changed to min to center vertically
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.child_care_rounded,
                                  color: widget.themeColor,
                                  size: 38,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  centerName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: widget.themeColor.withOpacity(0.8),
                                    letterSpacing: 0.5,
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
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.themeColor,
                      widget.themeColor.withBlue(widget.themeColor.blue + 30),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: widget.themeColor.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "SEMANA",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  Text(
                                    "$currentWeeks",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 56,
                                      height: 0.9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "🍎",
                                    style: const TextStyle(fontSize: 40),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Tamanho: ${babyData['fruit']}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "~ ${babyData['weight']}",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

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
                      color: Colors.blueAccent.withOpacity(0.1),
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
                    separatorBuilder: (_, __) => const SizedBox(width: 15),
                    itemBuilder: (context, index) {
                      return _buildPremiumTipCard(_aiTips[index], index);
                    },
                  ),
                ),

              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarFloat(
    Map<String, dynamic>? profile,
    Color color,
    double size,
    String label,
  ) {
    final String? photoUrl = profile?['photo_url'];
    return Column(
      children: [
        Container(
          width: size,
          height: size,
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
            radius: (size - 6) / 2, // Ensure it fits within the border
            backgroundColor: color.withValues(alpha: 0.1),
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(photoUrl)
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Text(
                    profile?['nickname']?[0]?.toUpperCase() ?? label[0],
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  )
                : null,
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
                    image: hasPhoto
                        ? DecorationImage(
                            image: NetworkImage(apt['photo_url']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: hasPhoto
                      ? null
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
