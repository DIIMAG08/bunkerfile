import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dream_track/shared/theme/app_theme.dart';
import 'package:dream_track/shared/widgets/common_widgets.dart';
import 'package:dream_track/shared/utils/date_utils.dart';
import 'package:dream_track/sleep/sleep_record_model.dart';
import 'package:dream_track/sleep/sleep_tracker_service.dart';

class SleepHistoryScreen extends ConsumerStatefulWidget {
  const SleepHistoryScreen({super.key});

  @override
  ConsumerState<SleepHistoryScreen> createState() => _SleepHistoryScreenState();
}

class _SleepHistoryScreenState extends ConsumerState<SleepHistoryScreen> {
  Future<void> _deleteRecord(int index, SleepRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Eliminar registro?',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar el registro de sueño del ${AppDateUtils.formatShortDate(record.bedTime)}? Esta acción no se puede deshacer.',
          style: const TextStyle(fontFamily: 'Nunito', color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Nunito')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontFamily: 'Nunito')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(sleepTrackerServiceProvider);
      
      // Since the list returned by getAllRecords is sorted (descending by bedtime),
      // we need to find the correct index in the Hive box to delete it.
      final records = service.getAllRecords();
      final recordIndex = records.indexOf(record);
      if (recordIndex != -1) {
        await service.deleteRecord(recordIndex);
        
        // Invalidate providers to refresh dashboard and charts
        ref.invalidate(sleepTrackerServiceProvider);
        ref.invalidate(allSleepRecordsProvider);
        ref.invalidate(lastSleepRecordProvider);
        ref.invalidate(weeklyRecordsProvider);
        ref.invalidate(monthlyRecordsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.delete_rounded, color: AppTheme.error),
                  SizedBox(width: 12),
                  Text('Registro eliminado correctamente', style: TextStyle(fontFamily: 'Nunito')),
                ],
              ),
              backgroundColor: AppTheme.surface,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  String _getQualityEmoji(int quality) {
    switch (quality) {
      case 5: return '🌟';
      case 4: return '😊';
      case 3: return '😐';
      case 2: return '😕';
      default: return '😴';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch all sleep records reactively
    final records = ref.watch(allSleepRecordsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: records.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(records),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Historial de Sueño', style: Theme.of(context).textTheme.headlineMedium),
              Text('Tus noches registradas', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('😴', style: TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin registros aún',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí aparecerán todas tus noches registradas. ¡Empieza a monitorizar tu sueño hoy mismo!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/register-sleep'),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Registrar Sueño', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<SleepRecord> records) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final r = records[index];
        return _buildHistoryCard(r, index);
      },
    );
  }

  Widget _buildHistoryCard(SleepRecord r, int index) {
    final emoji = _getQualityEmoji(r.quality);
    final hoursText = AppDateUtils.formatHoursSlept(r.hoursSlept);
    final isGood = r.hoursSlept >= 7.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section (emoji, date, times, delete button)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: r.qualityColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: r.qualityColor.withOpacity(0.4), width: 1.5),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppDateUtils.formatDate(r.bedTime),
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${AppDateUtils.formatTime(r.bedTime)} - ${AppDateUtils.formatTime(r.wakeTime)}',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hoursText,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isGood ? AppTheme.success : AppTheme.warning,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                      onPressed: () => _deleteRecord(index, r),
                    ),
                  ],
                ),
              ],
            ),

            // Middle section: details tags
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildTag('🔄 ${r.wakeUps} desp.', Colors.orange),
                if (r.hadDreams) _buildTag('☁️ Sueños', AppTheme.primary),
                if (r.hadNightmares) _buildTag('👹 Pesadillas', AppTheme.error),
                if (r.usedSounds) _buildTag('🎵 Relajante', Colors.purple),
                if (r.dndActive) _buildTag('🌙 No Molestar', AppTheme.secondary),
              ],
            ),

            // Bottom section: text notes (if any)
            if (r.notes != null && r.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: AppTheme.cardBorder, height: 1),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cardBorder.withOpacity(0.5)),
                ),
                child: Text(
                  r.notes!,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
