import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dream_track/stats/stats_service.dart';
import 'package:dream_track/shared/theme/app_theme.dart';
import 'package:dream_track/shared/utils/date_utils.dart';

class WeeklyChartWidget extends ConsumerStatefulWidget {
  const WeeklyChartWidget({super.key});

  @override
  ConsumerState<WeeklyChartWidget> createState() => _WeeklyChartWidgetState();
}

class _WeeklyChartWidgetState extends ConsumerState<WeeklyChartWidget> {
  WeeklySleepStats? _stats;
  double _goalHours = 8.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(statsServiceProvider);
    final stats = await service.getWeeklyStats(DateTime.now());
    if (mounted) {
      setState(() {
        _stats = stats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final stats = _stats;
    if (stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow(stats),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: _buildBarChart(stats),
        ),
        const SizedBox(height: 12),
        _buildDayLabels(),
      ],
    );
  }

  Widget _buildSummaryRow(WeeklySleepStats stats) {
    return Row(
      children: [
        _buildStatChip(
          '${stats.avgHours.toStringAsFixed(1)}h',
          'Promedio',
          AppTheme.primary,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          '${(stats.goalCompletionRate * 100).round()}%',
          'Meta cumplida',
          stats.goalCompletionRate >= 0.7 ? AppTheme.success : AppTheme.warning,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          stats.isImproving ? '+${stats.improvementVsPrevWeek.toStringAsFixed(1)}h' : '${stats.improvementVsPrevWeek.toStringAsFixed(1)}h',
          'vs semana ant.',
          stats.isImproving ? AppTheme.success : AppTheme.error,
        ),
      ],
    );
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(WeeklySleepStats stats) {
    final hours = stats.dailyHours;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 12,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppTheme.surface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${hours[group.x].toStringAsFixed(1)}h',
                const TextStyle(
                  color: AppTheme.textPrimary,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                return Text(
                  days[value.toInt()],
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontFamily: 'Nunito',
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontFamily: 'Nunito',
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppTheme.cardBorder,
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: _goalHours,
              color: AppTheme.success.withOpacity(0.5),
              strokeWidth: 2,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                labelResolver: (_) => 'Meta',
                style: const TextStyle(
                  color: AppTheme.success,
                  fontFamily: 'Nunito',
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        barGroups: List.generate(7, (i) {
          final h = hours[i];
          final metGoal = h >= _goalHours;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: h,
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: metGoal
                      ? [AppTheme.primary, AppTheme.primaryLight]
                      : [AppTheme.error.withOpacity(0.6), AppTheme.error],
                ),
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDayLabels() {
    final days = AppDateUtils.daysInWeek(DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(left: 36, right: 12),
      child: Row(
        children: days.map((day) {
          final isToday = AppDateUtils.isSameDay(day, DateTime.now());
          return Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  AppDateUtils.formatShortDate(day),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    color: isToday ? AppTheme.primary : AppTheme.textMuted,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
