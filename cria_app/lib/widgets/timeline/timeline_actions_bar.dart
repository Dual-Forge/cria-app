import 'package:flutter/material.dart';

import '../../features/parents/timeline/timeline_access.dart';

/// Barra de ações da linha do tempo (rodapé).
///
/// Hierarquia visual: botão primário ("Adicionar Memória") com cor de
/// destaque e botão secundário ("Ver como Stories") mais neutro. Oculta os
/// botões de criação quando o escopo não permite ([TimelineAccessScope]).
class TimelineActionsBar extends StatelessWidget {
  final TimelineAccessScope scope;
  final VoidCallback onAddMemory;
  final VoidCallback onViewStories;

  const TimelineActionsBar({
    super.key,
    required this.scope,
    required this.onAddMemory,
    required this.onViewStories,
  });

  @override
  Widget build(BuildContext context) {
    final canManage = scope.canManage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.8),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canManage) ...[
              // Primário
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 3,
                    shadowColor: Colors.deepPurple.withValues(alpha: 0.4),
                  ),
                  onPressed: onAddMemory,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Adicionar Memória',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Secundário
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple.shade300,
                  side: const BorderSide(color: Colors.deepPurple, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: onViewStories,
                icon: const Icon(Icons.auto_awesome_motion, size: 20),
                label: const Text(
                  'Ver como Stories',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 70), // Espaço da curved navigation bar
          ],
        ),
      ),
    );
  }
}