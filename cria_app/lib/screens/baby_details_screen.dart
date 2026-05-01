import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../utils/baby_data.dart';

class BabyDetailsScreen extends StatefulWidget {
  final String? profilePhotoUrl;
  final int? lastBpm;
  final DateTime? expectedDueDate;
  final DateTime? dumDate;
  final int kickCount;
  final String babyName;
  final String familyId;
  final Color themeColor;

  const BabyDetailsScreen({
    super.key,
    this.profilePhotoUrl,
    this.lastBpm,
    this.expectedDueDate,
    this.dumDate,
    required this.kickCount,
    required this.babyName,
    required this.familyId,
    required this.themeColor,
  });

  @override
  State<BabyDetailsScreen> createState() => _BabyDetailsScreenState();
}

class _BabyDetailsScreenState extends State<BabyDetailsScreen> with TickerProviderStateMixin {
  late int _currentBpm;
  late int _localKickCount;
  bool _isLoadingKick = false;

  // Audio Player
  late AudioPlayer _audioPlayer;
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  bool _isPlaying = false;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;

  // Colors
  final Color _bgColor = const Color(0xFFF8F4F9);
  final Color _pinkColor = const Color(0xFFE84199);
  final Color _blueColor = const Color(0xFF0096C7);

  @override
  void initState() {
    super.initState();
    _currentBpm = widget.lastBpm ?? 140;
    _localKickCount = widget.kickCount;

    _audioPlayer = AudioPlayer();
    _initializeHeartAnimation();
    _setupAudioPlayerListeners();
  }

  void _initializeHeartAnimation() {
    final durationMs = (60000 / _currentBpm).round();
    _heartController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );
    _heartScale = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
  }

  void _setupAudioPlayerListeners() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        setState(() => _isPlaying = true);
        _heartController.repeat(reverse: true);
      } else if (state == PlayerState.stopped || state == PlayerState.completed) {
        setState(() => _isPlaying = false);
        _heartController.stop();
        _heartController.reset();
      }
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      setState(() => _isPlaying = false);
      _heartController.stop();
      _heartController.reset();
    });
  }

  Future<void> _playHeartbeat() async {
    try {
      final playbackRate = (_currentBpm / 120.0).clamp(0.5, 2.0);
      await _audioPlayer.setPlaybackRate(playbackRate);

      final durationMs = (60000 / _currentBpm).round();
      _heartController.duration = Duration(milliseconds: durationMs);

      await _audioPlayer.play(AssetSource('audio/heartbeat.mp3'));
    } catch (e) {
      // Ignore error if audio doesn't exist during development
    }
  }

  Future<void> _stopHeartbeat() async {
    await _audioPlayer.stop();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _heartController.dispose();
    super.dispose();
  }

  int _calculateWeeks() {
    if (widget.dumDate == null) return 0;
    final diff = DateTime.now().difference(widget.dumDate!);
    int w = (diff.inDays / 7).floor();
    return w > 42 ? 42 : (w < 0 ? 0 : w);
  }

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

  Future<void> _registerKick() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.babyName} chutou?'),
        content: const Text('Deseja registrar esse movimento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _pinkColor),
            child: const Text('Registrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoadingKick = true);
    try {
      final newCount = _localKickCount + 1;
      await Supabase.instance.client
          .from('baby_profile')
          .update({'kick_count': newCount})
          .eq('family_id', widget.familyId);

      setState(() => _localKickCount = newCount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chute registrado! Total: $newCount'),
          backgroundColor: _pinkColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao registrar chute: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingKick = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int weeks = _calculateWeeks();
    final babyData = BabyData.getData(weeks);
    final size = babyData['size'] ?? '-';
    final weight = babyData['weight'] ?? '-';
    final fruitName = babyData['fruit'] ?? 'Sementinha';
    int month = _weekToMonth(weeks);

    int progressPercent = (weeks / 40 * 100).floor().clamp(0, 100);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.profilePhotoUrl != null && widget.profilePhotoUrl!.isNotEmpty)
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(widget.profilePhotoUrl!),
              )
            else
              const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                child: Icon(Icons.child_care, size: 18, color: Colors.pinkAccent),
              ),
            const SizedBox(width: 8),
            Text(
              'Informações da ${widget.babyName}',
              style: TextStyle(
                color: _pinkColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: _pinkColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildMainCard(size, weight),
            const SizedBox(height: 16),
            _buildDevelopmentCard(month, fruitName),
            const SizedBox(height: 16),
            _buildProgressCard(progressPercent, weeks),
            const SizedBox(height: 16),
            _buildKickButton(),
            const SizedBox(height: 16),
            _buildHeartbeatCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(String size, String weight) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Foto centralizada com borda dupla
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _pinkColor.withOpacity(0.2), width: 3),
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: _pinkColor.withOpacity(0.1),
                  backgroundImage: widget.profilePhotoUrl != null && widget.profilePhotoUrl!.isNotEmpty
                      ? NetworkImage(widget.profilePhotoUrl!)
                      : null,
                  child: widget.profilePhotoUrl == null || widget.profilePhotoUrl!.isEmpty
                      ? Icon(Icons.child_care, size: 40, color: _pinkColor)
                      : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.babyName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_border, size: 14, color: Colors.deepPurple),
              const SizedBox(width: 4),
              Text(
                'Áries', // Podemos tornar dinâmico com ZodiacBadge se necessário
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _pinkColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.scale, color: _pinkColor, size: 24),
                      const SizedBox(height: 8),
                      Text(
                        'PESO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _pinkColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weight,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _pinkColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _blueColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.straighten, color: _blueColor, size: 24),
                      const SizedBox(height: 8),
                      Text(
                        'TAMANHO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _blueColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        size,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _blueColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevelopmentCard(int month, String fruitName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.05), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/meses_bebe/mes_$month.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image, color: Colors.deepPurple, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tamanho de um(a) $fruitName',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.babyName} está crescendo rápido! O volume aproximado agora é de um(a) $fruitName.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int progressPercent, int weeks) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EAF0),
        borderRadius: BorderRadius.circular(24),
      ),
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
                    'PROGRESSO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '$progressPercent%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _pinkColor,
                    ),
                  ),
                ],
              ),
              Text(
                'Semana $weeks de 40',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressPercent / 100.0,
              minHeight: 14,
              backgroundColor: Colors.white.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation<Color>(_pinkColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKickButton() {
    return ElevatedButton(
      onPressed: _isLoadingKick ? null : _registerKick,
      style: ElevatedButton.styleFrom(
        backgroundColor: _pinkColor,
        elevation: 4,
        shadowColor: _pinkColor.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_border, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Text(
            'Registro de Chute',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: _isLoadingKick
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    '($_localKickCount)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartbeatCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _blueColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.monitor_heart, color: _blueColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Batimento Cardíaco',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: _blueColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _heartScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _heartScale.value,
                      child: Icon(Icons.monitor_heart_outlined, size: 40, color: _blueColor),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Text(
                      '$_currentBpm',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _blueColor,
                        height: 1,
                      ),
                    ),
                    Text(
                      'BPM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _blueColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _blueColor,
              inactiveTrackColor: _blueColor.withOpacity(0.1),
              thumbColor: _blueColor,
              trackHeight: 6,
            ),
            child: Slider(
              value: _currentBpm.toDouble(),
              min: 80,
              max: 200,
              onChanged: (value) {
                setState(() {
                  _currentBpm = value.toInt();
                  if (_isPlaying) {
                    _playHeartbeat(); // adjust speed while playing
                  }
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('80 BPM', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                Text('200 BPM', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isPlaying ? _stopHeartbeat : _playHeartbeat,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPlaying ? Colors.red : _blueColor,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              elevation: 4,
              shadowColor: (_isPlaying ? Colors.red : _blueColor).withOpacity(0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  _isPlaying ? 'Parar' : 'Ouvir Batimentos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
