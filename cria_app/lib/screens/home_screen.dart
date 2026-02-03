import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/baby_data.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb

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

  // Lista de pacientes para o Dropdown (Bebê + Pais)
  List<String> _patientsList = ['Bebê'];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _tabController = TabController(length: 2, vsync: this);
    _fetchFamilyNames(); // <--- Busca os nomes ao iniciar
  }

  // Busca nomes do pai e mãe para o dropdown
  Future<void> _fetchFamilyNames() async {
    if (widget.familyId == null) return;
    try {
      final profiles = await Supabase.instance.client
          .from('profiles')
          .select('nickname, role')
          .eq('family_id', widget.familyId!);

      List<String> loadedPatients = ['Bebê'];
      for (var p in profiles) {
        String role = p['role'] == 'mae'
            ? 'Mamãe'
            : (p['role'] == 'pai' ? 'Papai' : 'Outro');
        String name = p['nickname'] ?? '';
        if (name.isNotEmpty) {
          loadedPatients.add("$role ($name)");
        } else {
          loadedPatients.add(role);
        }
      }

      if (mounted) {
        setState(() {
          _patientsList = loadedPatients;
        });
      }
    } catch (e) {
      print("Erro ao buscar nomes: $e");
    }
  }

  int get _weeksPregnancy {
    if (widget.dumDate == null) return 0;
    final now = DateTime.now();
    final diff = now.difference(widget.dumDate!);
    int w = (diff.inDays / 7).floor();
    return w > 42 ? 42 : w;
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

  Future<void> _launchURL(String? url) async {
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Map<String, String> _getTipsForWeek(int week) {
    if (week < 12) {
      return {
        "body": "Seu corpo está se adaptando! Sono e náuseas são normais.",
        "diet": "Ácido Fólico e muita água.",
        "exercise": "Caminhadas leves.",
        "mental": "Descanse bastante.",
        "baby": "Coração já bate forte!",
      };
    } else if (week < 20) {
      return {
        "body": "A barriguinha aparece! Hidrate a pele para evitar estrias.",
        "diet": "Cálcio para os ossos.",
        "exercise": "Yoga ou Pilates.",
        "mental": "Converse com o bebê.",
        "baby": "Digitais se formando.",
      };
    } else if (week < 28) {
      return {
        "body": "O centro de gravidade muda. Cuidado com dores nas costas.",
        "diet": "Ferro contra anemia.",
        "exercise": "Hidroginástica.",
        "mental": "Pense no quartinho.",
        "baby": "Já ouve sua voz!",
      };
    } else {
      return {
        "body": "Reta final! Falta de ar é comum. Cuidado com o inchaço.",
        "diet": "Fibras.",
        "exercise": "Alongamentos.",
        "mental": "Mala da maternidade pronta?",
        "baby": "Ganhando peso.",
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: widget.themeColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: widget.themeColor,
          tabs: const [
            Tab(text: "Visão Geral"),
            Tab(text: "Agenda Médica"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverviewTab(), _buildAppointmentsTab()],
      ),
    );
  }

  // --- ABA 1: VISÃO GERAL ---
  Widget _buildOverviewTab() {
    final babyData = BabyData.getData(_weeksPregnancy);
    final tips = _getTipsForWeek(_weeksPregnancy);

    String centerName =
        widget.babyName?.toUpperCase() ??
        (widget.babyGender == 'menino'
            ? "MENINO"
            : (widget.babyGender == 'menina' ? "MENINA" : "BEBÊ"));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.familyId != null
                ? Supabase.instance.client
                      .from('profiles')
                      .stream(primaryKey: ['id'])
                      .eq('family_id', widget.familyId!)
                : const Stream.empty(),
            builder: (context, snapshot) {
              Map<String, dynamic>? momProfile;
              Map<String, dynamic>? dadProfile;

              if (snapshot.hasData) {
                final profiles = snapshot.data!;
                try {
                  momProfile = profiles.firstWhere((p) => p['role'] == 'mae');
                } catch (_) {}
                try {
                  dadProfile = profiles.firstWhere((p) => p['role'] == 'pai');
                } catch (_) {}
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAvatarLarge(dadProfile, Colors.blue, "Pai"),
                    Icon(Icons.favorite, color: Colors.red.shade200, size: 24),
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: widget.themeColor.withOpacity(0.1),
                          child: Icon(
                            Icons.child_friendly,
                            color: widget.themeColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          centerName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.themeColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.favorite, color: Colors.red.shade200, size: 24),
                    _buildAvatarLarge(momProfile, Colors.pink, "Mãe"),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 25),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: widget.themeColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.themeColor.withOpacity(0.85),
                        widget.themeColor,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Semana $_weeksPregnancy",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Tamanho: ${babyData['fruit']}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Peso aprox: ${babyData['weight']}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Text("🍎", style: TextStyle(fontSize: 40)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: widget.themeColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pregnant_woman, color: widget.themeColor),
                          const SizedBox(width: 8),
                          Text(
                            "O Corpo da Mamãe",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.themeColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tips['body']!,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),
          Row(
            children: [
              Icon(Icons.auto_awesome, color: widget.themeColor),
              const SizedBox(width: 8),
              const Text(
                "Dicas Rápidas",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildInfoCard(
                Icons.restaurant,
                "Nutrição",
                tips['diet']!,
                Colors.orange,
              ),
              _buildInfoCard(
                Icons.directions_walk,
                "Movimento",
                tips['exercise']!,
                Colors.blue,
              ),
              _buildInfoCard(
                Icons.self_improvement,
                "Bem-estar",
                tips['mental']!,
                Colors.purple,
              ),
              _buildInfoCard(
                Icons.child_care,
                "Foco no Bebê",
                tips['baby']!,
                Colors.pink,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- ABA 2: AGENDA MÉDICA ---
  Widget _buildAppointmentsTab() {
    if (widget.familyId == null)
      return const Center(child: Text("Carregando família..."));

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
              if (DateTime.parse(item['appointment_date']).isAfter(now))
                displayEvents.add(item);
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
          for (var list in _events.values) displayEvents.addAll(list);
          displayEvents.sort(
            (a, b) => b['appointment_date'].compareTo(a['appointment_date']),
          );
        }

        return Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getEventsForDay,
                    calendarStyle: CalendarStyle(
                      markerDecoration: BoxDecoration(
                        color: widget.themeColor,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: widget.themeColor.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: widget.themeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onDaySelected: (s, f) => setState(() {
                      _selectedDay = s;
                      _focusedDay = f;
                      _calendarView = 'Dia';
                    }),
                    onPageChanged: (f) => _focusedDay = f,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          "Dia Selecionado",
                          _calendarView == 'Dia',
                          () => setState(() => _calendarView = 'Dia'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          "Próximas Consultas",
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
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: displayEvents.isEmpty
                  ? Center(
                      child: Text(
                        "Nenhum agendamento.",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayEvents.length,
                      itemBuilder: (context, index) =>
                          _buildAppointmentCard(displayEvents[index]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddAppointmentSheet(widget.familyId!),
                  icon: const Icon(Icons.add),
                  label: const Text("Nova Consulta"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- MÉTODOS AUXILIARES ---
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isSelected ? widget.themeColor : Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Colors.transparent : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> apt) {
    final date = DateTime.parse(apt['appointment_date']);
    final hasPhoto = apt['photo_url'] != null;
    final address = apt['address'];
    return GestureDetector(
      onTap: () => _showAppointmentDetails(apt),
      child: Card(
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              GestureDetector(
                onTap: hasPhoto ? () => _launchURL(apt['photo_url']) : null,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: widget.themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
                          size: 30,
                        ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apt['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: widget.themeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM • HH:mm').format(date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.themeColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Paciente: ${apt['patient_name'] ?? '-'}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    Text(
                      "Dr(a): ${apt['doctor_name'] ?? '-'}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (address != null && address.toString().isNotEmpty)
                IconButton(
                  onPressed: () => _openMap(address),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  tooltip: "Abrir Mapa",
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> apt) {
    final date = DateTime.parse(apt['appointment_date']);
    final hasPhoto = apt['photo_url'] != null;
    final address = apt['address'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 20),
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
                  Expanded(
                    child: Column(
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
              if (address != null && address.isNotEmpty) ...[
                const SizedBox(height: 15),
                InkWell(
                  onTap: () => _openMap(address),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (apt['notes'] != null && apt['notes'].isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  "Observações",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    apt['notes'],
                    style: TextStyle(color: Colors.brown[700]),
                  ),
                ),
              ],
              if (hasPhoto) ...[
                const SizedBox(height: 20),
                const Text(
                  "Anexo",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _launchURL(apt['photo_url']),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.network(
                          apt['photo_url'],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Toque para ampliar",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Supabase.instance.client
                        .from('appointments')
                        .delete()
                        .eq('id', apt['id']);
                    if (mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    "Excluir Consulta",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // --- NOVA CONSULTA (CORRIGIDA) ---
  void _showAddAppointmentSheet(String familyId) {
    final titleController = TextEditingController();
    final doctorController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    // Usa a lista carregada no initState, se estiver vazia usa o padrão
    List<String> currentPatients = _patientsList.isNotEmpty
        ? _patientsList
        : ['Bebê'];
    String? selectedPatient = currentPatients.first;

    File? mobileImageFile;
    Uint8List? webImageBytes;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            Future<void> pickImage(ImageSource source) async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: source,
                imageQuality: 50,
              );
              if (picked != null) {
                if (kIsWeb) {
                  final bytes = await picked.readAsBytes();
                  setStateModal(() => webImageBytes = bytes);
                } else {
                  setStateModal(() => mobileImageFile = File(picked.path));
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    "Agendar Consulta",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.themeColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DROPDOWN PACIENTE (Agora com a lista certa)
                  DropdownButtonFormField<String>(
                    value: selectedPatient,
                    decoration: const InputDecoration(
                      labelText: "Paciente",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: currentPatients
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setStateModal(() => selectedPatient = v),
                  ),

                  const SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Especialidade (Ex: Obstetra)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.star),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: doctorController,
                    decoration: const InputDecoration(
                      labelText: "Nome do Médico",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medical_services),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: "Endereço / Local",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (d != null)
                              setStateModal(() => selectedDate = d);
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(DateFormat('dd/MM').format(selectedDate)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (t != null)
                              setStateModal(() => selectedTime = t);
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(selectedTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Observações",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Anexo (Receita/Pedido)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (mobileImageFile != null || webImageBytes != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.memory(
                                  webImageBytes!,
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  mobileImageFile!,
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        IconButton(
                          onPressed: () => setStateModal(() {
                            mobileImageFile = null;
                            webImageBytes = null;
                          }),
                          icon: const CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 15,
                            child: Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Câmera"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo),
                            label: const Text("Galeria"),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // BOTÃO SALVAR (Com Try/Catch e Feedback)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isUploading
                          ? null
                          : () async {
                              // Validação Simples
                              if (titleController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Preencha a especialidade!"),
                                  ),
                                );
                                return;
                              }

                              setStateModal(() => isUploading = true);

                              try {
                                final user =
                                    Supabase.instance.client.auth.currentUser;
                                String? uploadedUrl;

                                // Upload Imagem
                                if (mobileImageFile != null ||
                                    webImageBytes != null) {
                                  try {
                                    final fileName =
                                        'docs/${user!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                    if (kIsWeb && webImageBytes != null) {
                                      await Supabase.instance.client.storage
                                          .from('diary_photos')
                                          .uploadBinary(
                                            fileName,
                                            webImageBytes!,
                                            fileOptions: const FileOptions(
                                              contentType: 'image/jpeg',
                                            ),
                                          );
                                    } else if (mobileImageFile != null) {
                                      await Supabase.instance.client.storage
                                          .from('diary_photos')
                                          .upload(fileName, mobileImageFile!);
                                    }
                                    uploadedUrl = Supabase
                                        .instance
                                        .client
                                        .storage
                                        .from('diary_photos')
                                        .getPublicUrl(fileName);
                                  } catch (e) {
                                    print("Erro foto (ignorado): $e");
                                  }
                                }

                                final finalDate = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                );

                                // Insert Seguro
                                await Supabase.instance.client
                                    .from('appointments')
                                    .insert({
                                      'family_id': familyId,
                                      'title': titleController.text,
                                      'doctor_name': doctorController.text,
                                      'address': addressController.text,
                                      'notes': notesController.text,
                                      'appointment_date': finalDate
                                          .toIso8601String(),
                                      'patient_name': selectedPatient,
                                      'photo_url': uploadedUrl,
                                    });

                                if (mounted) Navigator.pop(context);
                              } catch (e) {
                                print("ERRO AO SALVAR CONSULTA: $e");
                                setStateModal(() => isUploading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Erro ao salvar: $e")),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.themeColor,
                        foregroundColor: Colors.white,
                      ),
                      child: isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Salvar Consulta"),
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

  Widget _buildAvatarLarge(
    Map<String, dynamic>? profile,
    Color color,
    String label,
  ) {
    String? photo = profile?['photo_url'];
    if (photo != null) {
      final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      photo = "$photo?v=$uniqueId";
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: color.withOpacity(0.1),
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null
                ? Text(
                    profile?['nickname']?[0].toUpperCase() ?? label[0],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: color,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          profile?['nickname'] ?? label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(color: Colors.grey[700], fontSize: 11),
              overflow: TextOverflow.fade,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
