import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'profile_photo_widget.dart';
import 'bpm_display_widget.dart';
import 'zodiac_badge_widget.dart';
import 'trimestre_progress_bar.dart';
import 'kick_counter_button.dart';
import '../../utils/baby_data.dart';

class SizeAndWeightDisplayWidget extends StatelessWidget {
  final DateTime? dumDate;
  final Color themeColor;

  const SizeAndWeightDisplayWidget({super.key, this.dumDate, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    if (dumDate == null) return const SizedBox.shrink();
    
    final diff = DateTime.now().difference(dumDate!);
    int weeks = (diff.inDays / 7).floor();
    if (weeks < 0) weeks = 0;
    
    final babyData = BabyData.getData(weeks);
    final size = babyData['size'] ?? '-';
    final weight = babyData['weight'] ?? '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.straighten, size: 14, color: themeColor),
          const SizedBox(width: 4),
          Text(size, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: themeColor)),
          const SizedBox(width: 12),
          Icon(Icons.scale, size: 14, color: themeColor),
          const SizedBox(width: 4),
          Text(weight, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: themeColor)),
        ],
      ),
    );
  }
}

/// BabyCardWidget
/// 
/// Componente principal que integra todos os sub-componentes do cartão do bebê.
/// Exibe foto de perfil, BPM, zodíaco, progresso do trimestre e contador de chutes.
/// Segue o design Bento com cores pastel e espaçamento consistente.
class BabyCardWidget extends StatelessWidget {
  /// URL da foto de perfil do bebê
  final String? profilePhotoUrl;

  /// Frequência cardíaca em BPM
  final int? lastBpm;

  /// Data prevista do parto
  final DateTime? expectedDueDate;

  /// Data da última menstruação (DUM)
  final DateTime? dumDate;

  /// Contador de chutes
  final int kickCount;

  /// Nome do bebê
  final String babyName;

  /// ID da família
  final String familyId;

  /// Cor do tema
  final Color themeColor;

  /// Callback quando o contador de chutes é atualizado
  final Function(int newCount)? onKickCountUpdated;

  /// Callback para erros
  final Function(String error)? onError;

  /// Mostrar BPM
  final bool showBpm;

  /// Mostrar zodíaco
  final bool showZodiac;

  /// Mostrar progresso do trimestre
  final bool showTrimestreProgress;

  /// Mostrar contador de chutes
  final bool showKickCounter;

  /// Tamanho da foto de perfil
  final double photoSize;

  const BabyCardWidget({
    super.key,
    this.profilePhotoUrl,
    this.lastBpm,
    this.expectedDueDate,
    this.dumDate,
    required this.kickCount,
    required this.babyName,
    required this.familyId,
    required this.themeColor,
    this.onKickCountUpdated,
    this.onError,
    this.showBpm = true,
    this.showZodiac = true,
    this.showTrimestreProgress = true,
    this.showKickCounter = true,
    this.photoSize = 130,
  });

  @override
  Widget build(BuildContext context) {
    int weeks = 0;
    if (dumDate != null) {
      final diff = DateTime.now().difference(dumDate!);
      weeks = (diff.inDays / 7).floor();
      if (weeks < 0) weeks = 0;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push('/baby-details', extra: {
            'profilePhotoUrl': profilePhotoUrl,
            'lastBpm': lastBpm,
            'expectedDueDate': expectedDueDate,
            'dumDate': dumDate,
            'kickCount': kickCount,
            'babyName': babyName,
            'familyId': familyId,
            'themeColor': themeColor,
          });
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Foto Redonda
              ProfilePhotoWidget(
                photoUrl: profilePhotoUrl,
                themeColor: themeColor,
                size: 80,
              ),
              const SizedBox(width: 16),
              
              // Coluna de Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      babyName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Semana $weeks',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Signo e Registro de Chute
                    Row(
                      children: [
                        if (showZodiac)
                          ZodiacBadgeWidget(
                            expectedDueDate: expectedDueDate,
                            themeColor: themeColor,
                            emojiSize: 14,
                            textSize: 12,
                          ),
                        const SizedBox(width: 8),
                        KickCounterCompactButton(
                          kickCount: kickCount,
                          babyName: babyName,
                          familyId: familyId,
                          themeColor: themeColor,
                          onKickCountUpdated: onKickCountUpdated,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    // Peso e Tamanho
                    SizeAndWeightDisplayWidget(
                      dumDate: dumDate,
                      themeColor: themeColor,
                    ),
                  ],
                ),
              ),
              
              // Seta Indicadora
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// BabyCardCompactWidget
/// 
/// Versão compacta do BabyCardWidget para espaços limitados.
class BabyCardCompactWidget extends StatelessWidget {
  /// URL da foto de perfil do bebê
  final String? profilePhotoUrl;

  /// Frequência cardíaca em BPM
  final int? lastBpm;

  /// Data prevista do parto
  final DateTime? expectedDueDate;

  /// Data da última menstruação (DUM)
  final DateTime? dumDate;

  /// Contador de chutes
  final int kickCount;

  /// Nome do bebê
  final String babyName;

  /// ID da família
  final String familyId;

  /// Cor do tema
  final Color themeColor;

  /// Callback quando o contador de chutes é atualizado
  final Function(int newCount)? onKickCountUpdated;

  const BabyCardCompactWidget({
    super.key,
    this.profilePhotoUrl,
    this.lastBpm,
    this.expectedDueDate,
    this.dumDate,
    required this.kickCount,
    required this.babyName,
    required this.familyId,
    required this.themeColor,
    this.onKickCountUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Foto + Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfilePhotoWidget(
                  photoUrl: profilePhotoUrl,
                  themeColor: themeColor,
                  size: 80,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        babyName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (lastBpm != null)
                        BPMDisplayCompactWidget(
                          lastBpm: lastBpm,
                          themeColor: themeColor,
                        ),
                      const SizedBox(height: 6),
                      ZodiacBadgeWidget(
                        expectedDueDate: expectedDueDate,
                        themeColor: themeColor,
                        emojiSize: 16,
                        textSize: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TrimestreProgressBarCompact(
              dumDate: dumDate,
              themeColor: themeColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// BabyCardDetailedWidget
/// 
/// Versão detalhada com mais informações e interatividade.
class BabyCardDetailedWidget extends StatelessWidget {
  /// URL da foto de perfil do bebê
  final String? profilePhotoUrl;

  /// Frequência cardíaca em BPM
  final int? lastBpm;

  /// Data prevista do parto
  final DateTime? expectedDueDate;

  /// Data da última menstruação (DUM)
  final DateTime? dumDate;

  /// Contador de chutes
  final int kickCount;

  /// Nome do bebê
  final String babyName;

  /// ID da família
  final String familyId;

  /// Cor do tema
  final Color themeColor;

  /// Callback quando o contador de chutes é atualizado
  final Function(int newCount)? onKickCountUpdated;

  /// Callback para erros
  final Function(String error)? onError;

  /// Tamanho da foto de perfil
  final double photoSize;

  const BabyCardDetailedWidget({
    super.key,
    this.profilePhotoUrl,
    this.lastBpm,
    this.expectedDueDate,
    this.dumDate,
    required this.kickCount,
    required this.babyName,
    required this.familyId,
    required this.themeColor,
    this.onKickCountUpdated,
    this.onError,
    this.photoSize = 130,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Foto + Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfilePhotoWithBorderWidget(
                  photoUrl: profilePhotoUrl,
                  themeColor: themeColor,
                  size: photoSize,
                  borderColor: themeColor.withOpacity(0.3),
                  borderWidth: 2,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        babyName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (lastBpm != null)
                        BPMDisplayWidget(
                          lastBpm: lastBpm,
                          themeColor: themeColor,
                        ),
                      const SizedBox(height: 12),
                      ZodiacBadgeDetailedWidget(
                        expectedDueDate: expectedDueDate,
                        themeColor: themeColor,
                        showDueDate: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Progresso do Trimestre (Detalhado)
            TrimestreProgressBarDetailed(
              dumDate: dumDate,
              themeColor: themeColor,
              showMilestone: true,
              showDaysRemaining: true,
            ),

            const SizedBox(height: 24),

            // Contador de Chutes
            KickCounterButton(
              kickCount: kickCount,
              babyName: babyName,
              familyId: familyId,
              themeColor: themeColor,
              onKickCountUpdated: onKickCountUpdated,
              onError: onError,
            ),
          ],
        ),
      ),
    );
  }
}

/// BabyCardMinimalWidget
/// 
/// Versão minimalista com apenas informações essenciais.
class BabyCardMinimalWidget extends StatelessWidget {
  /// URL da foto de perfil do bebê
  final String? profilePhotoUrl;

  /// Nome do bebê
  final String babyName;

  /// Cor do tema
  final Color themeColor;

  /// Data prevista do parto
  final DateTime? expectedDueDate;

  /// Contador de chutes
  final int kickCount;

  /// ID da família
  final String familyId;

  /// Callback quando o contador de chutes é atualizado
  final Function(int newCount)? onKickCountUpdated;

  const BabyCardMinimalWidget({
    super.key,
    this.profilePhotoUrl,
    required this.babyName,
    required this.themeColor,
    this.expectedDueDate,
    required this.kickCount,
    required this.familyId,
    this.onKickCountUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ProfilePhotoWidget(
              photoUrl: profilePhotoUrl,
              themeColor: themeColor,
              size: 60,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    babyName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ZodiacBadgeWidget(
                    expectedDueDate: expectedDueDate,
                    themeColor: themeColor,
                    emojiSize: 14,
                    textSize: 11,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            KickCounterCompactButton(
              kickCount: kickCount,
              babyName: babyName,
              familyId: familyId,
              themeColor: themeColor,
              onKickCountUpdated: onKickCountUpdated,
            ),
          ],
        ),
      ),
    );
  }
}
