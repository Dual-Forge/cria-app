import 'package:flutter/material.dart';

import '../../features/parents/timeline/memory_event.dart';
import '../../features/parents/timeline/timeline_access.dart';

/// Card de uma memória da linha do tempo.
///
/// Exibe avatar (imagem/vídeo), idade, data e descrição, com um menu de
/// contexto ([PopupMenuButton]) no canto. Botões de criação/edição/exclusão
/// são condicionados a [TimelineAccessScope.canEdit] — pronto para o futuro
/// "Modo Convidado" (apenas leitura, curtir e comentar).
class TimelineMemoryCard extends StatelessWidget {
  final MemoryEvent event;
  final TimelineAccessScope scope;

  /// Exibição da faixa da idade (ex.: "3 Meses").
  final String ageLabel;
  final String formattedDate;

  final VoidCallback onAvatarTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetAsProfile;

  const TimelineMemoryCard({
    super.key,
    required this.event,
    required this.scope,
    required this.ageLabel,
    required this.formattedDate,
    required this.onAvatarTap,
    required this.onEdit,
    required this.onDelete,
    this.onSetAsProfile,
  });

  @override
  Widget build(BuildContext context) {
    final canEdit = scope.canEdit;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          GestureDetector(
            onTap: onAvatarTap,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child: event.isVideo
                    ? Container(
                        color: Colors.black87,
                        width: 80,
                        height: 80,
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white70,
                            size: 32,
                          ),
                        ),
                      )
                    : Image.network(
                        event.mediaUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title.isEmpty ? 'Memória' : event.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                if (event.description.trim().isNotEmpty)
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),

          // Menu de contexto (RBAC)
          if (canEdit)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                  case 'delete':
                    onDelete();
                  case 'profile':
                    onSetAsProfile?.call();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.deepPurple.shade300, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Editar',
                        style: TextStyle(color: Colors.deepPurple.shade300),
                      ),
                    ],
                  ),
                ),
                if (onSetAsProfile != null)
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Definir como foto de perfil',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}