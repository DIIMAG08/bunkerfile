import 'package:flutter/material.dart';
import 'package:dream_track/shared/theme/app_theme.dart';

class QuickActionsWidget extends StatelessWidget {
  final bool sleepModeActive;
  final VoidCallback onSleepMode;
  final VoidCallback onWakeAndRegister;
  final VoidCallback onAiChat;
  final VoidCallback onRegisterSleep;
  final VoidCallback onStats;
  final VoidCallback onReminders;

  const QuickActionsWidget({
    super.key,
    required this.sleepModeActive,
    required this.onSleepMode,
    required this.onWakeAndRegister,
    required this.onAiChat,
    required this.onRegisterSleep,
    required this.onStats,
    required this.onReminders,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Seguimiento del sueño', style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 12),
        // Prominent Sleep/Wake state action button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildMainSleepButton(context),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Accesos rápidos', style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 12),
        // Secondary actions grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: _buildActionCard(
                context,
                emoji: '🤖',
                label: 'Asistente',
                color: AppTheme.primary,
                onTap: onAiChat,
              )),
              const SizedBox(width: 10),
              Expanded(child: _buildActionCard(
                context,
                emoji: '📊',
                label: 'Estadísticas',
                color: AppTheme.info,
                onTap: onStats,
              )),
              const SizedBox(width: 10),
              Expanded(child: _buildActionCard(
                context,
                emoji: '✏️',
                label: 'Historial',
                color: AppTheme.success,
                onTap: onRegisterSleep,
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainSleepButton(BuildContext context) {
    final isDormir = !sleepModeActive;

    return GestureDetector(
      onTap: isDormir ? onSleepMode : onWakeAndRegister,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isDormir
              ? AppTheme.primaryGradient
              : const LinearGradient(
                  colors: [Color(0xFFFF7E40), Color(0xFFFFB300)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isDormir ? AppTheme.primary : const Color(0xFFFF7E40)).withOpacity(0.35),
              blurRadius: 24,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: (isDormir ? AppTheme.primaryLight : const Color(0xFFFFBE76)).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with pulsing anim simulation
            Text(isDormir ? '🌙' : '☀️', style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDormir ? 'DORMIR AHORA' : 'DESPERTAR Y REGISTRAR',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isDormir
                        ? 'Inicia el monitoreo y silencia notificaciones'
                        : 'Finaliza el monitoreo y guarda tu descanso',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String emoji,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
