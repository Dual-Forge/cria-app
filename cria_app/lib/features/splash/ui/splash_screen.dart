import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cria_app/app/app_dependencies.dart';
import 'package:go_router/go_router.dart';
import '../../parents/ui/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  late AnimationController _textPulseController;

  Stream<Map<String, dynamic>>? _familyStream;
  String? _familyId;
  bool _isLoading = true;

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

    _textPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _setupRealtimeListener();
  }

  Future<void> _setupRealtimeListener() async {
    debugPrint('[SplashScreen] _setupRealtimeListener iniciado');
    final user = AppDependencies.client.auth.currentUser;
    if (user == null) {
      debugPrint('[SplashScreen] Usuário não logado, redirecionando para /login');
      // Redireciona para login diretamente — evita loop via '/' → AuthGateScreen → SplashScreen
      if (mounted) context.go('/login');
      return;
    }

    debugPrint('[SplashScreen] Usuário: ${user.id} — consultando perfil...');
    try {
      // Timeout de 10s: se a rede travar no Android, não fica em loading infinito
      final profile = await AppDependencies.client
          .from('profiles')
          .select('family_id')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('[SplashScreen] TIMEOUT na consulta de perfil! Continuando sem dados.');
              return null;
            },
          );

      debugPrint('[SplashScreen] Perfil recebido: $profile');

      if (profile != null && profile['family_id'] != null) {
        if (mounted) {
          setState(() {
            _familyId = profile['family_id'];
            _familyStream = AppDependencies.client
                .from('families')
                .stream(primaryKey: ['id'])
                .eq('id', _familyId!)
                .map((event) => event.isNotEmpty ? event.first : <String, dynamic>{});
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('[SplashScreen] Erro em _setupRealtimeListener: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    _textPulseController.dispose();
    super.dispose();
  }

  Widget _buildDynamicTitle(
    DateTime? actualDumDate,
    String? babyName,
    Color themeColor,
  ) {
    String nameToDisplay = babyName ?? "seu bebê";
    String textPrefix = "Aguardando a chegada de ";
    String textSuffix = "";
    bool isBorn = false;

    if (actualDumDate != null) {
      final edd = actualDumDate.add(const Duration(days: 280));
      final daysRemaining = edd.difference(DateTime.now()).inDays;

      if (daysRemaining > 0) {
        textPrefix =
            "Faltam aproximadamente $daysRemaining dias para a chegada de ";
        textSuffix = "";
      } else if (daysRemaining == 0) {
        textPrefix = "É hoje! O grande dia da chegada de ";
        textSuffix = "";
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (textPrefix.isNotEmpty) ...[
                  Text(
                    textPrefix,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.petitFormalScript(
                      fontSize: 26,
                      color: const Color(0xFF2D3142),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Transform.scale(
                  scale: _heartScale.value,
                  child: Text(
                    nameToDisplay,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.petitFormalScript(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                      shadows: [
                        Shadow(
                          color: themeColor.withValues(alpha: 0.5),
                          blurRadius: 10 * _heartScale.value,
                        ),
                      ],
                    ),
                  ),
                ),
                if (textSuffix.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    textSuffix,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.petitFormalScript(
                      fontSize: 26,
                      color: const Color(0xFF2D3142),
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBabyAvatar(
    String centerName,
    String? photoUrl,
    Color themeColor,
  ) {
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
                color: themeColor.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: themeColor.withValues(alpha: 0.05),
            child: (photoUrl != null && photoUrl.isNotEmpty)
                ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.child_care_rounded,
                        color: themeColor,
                        size: 40,
                      ),
                    ),
                  )
                : Icon(Icons.child_care_rounded, color: themeColor, size: 40),
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
    String label,
  ) {
    final String? photoUrl = profile?['photo_url'];
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: _familyStream,
      builder: (context, snapshot) {
        Color themeColor = Colors.purple;
        String? babyName;
        String? babyGender;
        DateTime? dumDate;
        String? babyPhotoUrl;

        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          babyName = data['baby_name'];
          babyGender = data['baby_gender'];
          babyPhotoUrl = data['baby_photo_url'];

          if (data['dum_date'] != null) {
            dumDate = DateTime.parse(data['dum_date']);
          }

          if (babyGender == 'menino') {
            themeColor = const Color(0xFF64B5F6);
          } else if (babyGender == 'menina') {
            themeColor = const Color(0xFFF06292);
          } else {
            themeColor = Colors.deepPurple.shade300;
          }
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: GestureDetector(
              onTap: () {
                context.go('/home');
              },
            behavior: HitTestBehavior.opaque,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _familyId != null
                  ? AppDependencies.client
                        .from('profiles')
                        .stream(primaryKey: ['id'])
                        .eq('family_id', _familyId!)
                  : const Stream.empty(),
              builder: (context, profilesSnapshot) {
                Map<String, dynamic>? momProfile;
                Map<String, dynamic>? dadProfile;
                DateTime? actualDumDate = dumDate;

                if (profilesSnapshot.hasData) {
                  final profiles = profilesSnapshot.data!;
                  try {
                    momProfile = profiles.firstWhere((p) => p['role'] == 'mae');
                    if (momProfile['dum_date'] != null) {
                      actualDumDate = DateTime.parse(momProfile['dum_date']);
                    }
                  } catch (_) {}
                  try {
                    dadProfile = profiles.firstWhere((p) => p['role'] == 'pai');
                  } catch (_) {}
                }

                String centerName =
                    babyName?.toUpperCase() ??
                    (babyGender == 'menino'
                        ? "MENINO"
                        : (babyGender == 'menina' ? "MENINA" : "BEBÊ"));

                final double screenWidth = MediaQuery.of(context).size.width;
                final double heartContainerSize = screenWidth * 0.85;

                return SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      Transform.translate(
                        offset: const Offset(0, 45),
                        child: _buildDynamicTitle(
                          actualDumDate,
                          babyName,
                          themeColor,
                        ),
                      ),
                      SizedBox(
                        width: heartContainerSize,
                        height: heartContainerSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
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
                                      color: themeColor.withValues(alpha: 0.08),
                                    ),
                                  ),
                                );
                              },
                            ),
                            CustomPaint(
                              size: Size(
                                heartContainerSize,
                                heartContainerSize,
                              ),
                              painter: HeartDashedPathPainter(
                                color: themeColor.withValues(alpha: 0.6),
                              ),
                            ),
                            Positioned(
                              left: heartContainerSize * 0.10,
                              top: heartContainerSize * 0.15,
                              child: _buildAvatarFloat(
                                momProfile,
                                Colors.pinkAccent.shade100,
                                momProfile?['nickname'] ?? "Mamãe",
                              ),
                            ),
                            Positioned(
                              right: heartContainerSize * 0.10,
                              top: heartContainerSize * 0.15,
                              child: _buildAvatarFloat(
                                dadProfile,
                                Colors.blueGrey,
                                dadProfile?['nickname'] ?? "Papai",
                              ),
                            ),
                            Positioned(
                              bottom: heartContainerSize * 0.0,
                              child: _buildBabyAvatar(
                                centerName,
                                babyPhotoUrl,
                                themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 2),
                      AnimatedBuilder(
                        animation: _textPulseController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 0.4 + (_textPulseController.value * 0.6),
                            child: Text(
                              "Toque em qualquer lugar para entrar",
                              style: TextStyle(
                                color: themeColor.withValues(alpha: 0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                );
              },
            ),
          ),
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
    canvas.drawPath(_createHeartPath(size), paint);
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
  path.moveTo(0.5 * width, height * 0.35);
  path.cubicTo(
    0.2 * width,
    height * 0.05,
    -0.25 * width,
    height * 0.45,
    0.5 * width,
    height * 0.90,
  );
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
