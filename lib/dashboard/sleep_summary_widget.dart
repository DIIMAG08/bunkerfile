import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dream_track/sleep/sleep_tracker_service.dart';
import 'package:dream_track/sleep/sleep_record_model.dart';
import 'package:dream_track/shared/theme/app_theme.dart';
import 'package:dream_track/shared/utils/date_utils.dart';
import 'package:dream_track/shared/widgets/common_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SleepSummaryWidget extends ConsumerStatefulWidget {
  const SleepSummaryWidget({super.key});

  @override
  ConsumerState<SleepSummaryWidget> createState() => _SleepSummaryWidgetState();
}

class _SleepSummaryWidgetState extends ConsumerState<SleepSummaryWidget> {
  double _goalHours = 8.0;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _goalHours = prefs.getDouble('sleepGoalHours') ?? 8.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastRecord = ref.watch(lastSleepRecordProvider);

    if (lastRecord == null) {
      return _buildNoDataCard();
    }

    return _buildSummaryCard(lastRecord);
  }

  Widget _buildNoDataCard() {
    return GlassCard(
      child: Column(
        children: [
          const Text('💤', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Sin registros aún',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Registra tu primera noche de sueño para\nver tu resumen aquí.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(SleepRecord record) {
    final metGoal = record.hoursSlept >= _goalHours;
    final hoursText = AppDateUtils.formatHoursSlept(record.hoursSlept);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Anoche', style: Theme.of(context).textTheme.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (metGoal ? AppTheme.success : AppTheme.warning).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  metGoal ? '✓ Meta cumplida' : '! Debajo de la meta',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: metGoal ? AppTheme.success : AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hoursText,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: metGoal ? AppTheme.success : AppTheme.warning,
                        fontSize: 40,
                      ),
                    ),
                    Text(
                      'horas dormidas',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: List.generate(5, (i) => Icon(
                      i < record.quality ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppTheme.warning,
                      size: 20,
                    )),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.qualityLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTimeChip(
                Icons.bedtime_rounded,
                AppDateUtils.formatTime(record.bedTime),
                'Dormí',
                AppTheme.secondary,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: AppTheme.textMuted, size: 16),
              const SizedBox(width: 8),
              _buildTimeChip(
                Icons.wb_sunny_rounded,
                AppDateUtils.formatTime(record.wakeTime),
                'Desperté',
                AppTheme.warning,
              ),
              const Spacer(),
              if (record.wakeUps > 0)
                _buildPillBadge('${record.wakeUps}x 🌙', AppTheme.info),
            ],
          ),
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '"${record.notes}"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeChip(IconData icon, String time, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              time,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPillBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
